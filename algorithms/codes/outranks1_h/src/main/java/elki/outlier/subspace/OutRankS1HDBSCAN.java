/*
 * This file is part of ELKI:
 * Environment for Developing KDD-Applications Supported by Index-Structures
 * 
 * Copyright (C) 2022
 * ELKI Development Team
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
package elki.outlier.subspace;

import java.util.Arrays;
import java.util.Random;

import elki.clustering.hierarchical.extraction.HDBSCANHierarchyExtraction;
import elki.data.Cluster;
import elki.data.Clustering;
import elki.data.NumberVector;
import elki.data.projection.NumericalFeatureSelection;
import elki.data.type.SimpleTypeInformation;
import elki.data.type.TypeInformation;
import elki.data.type.TypeUtil;
import elki.data.type.VectorFieldTypeInformation;
import elki.database.Database;
import elki.database.StaticArrayDatabase;
import elki.database.datastore.DataStoreFactory;
import elki.database.datastore.DataStoreUtil;
import elki.database.datastore.WritableDoubleDataStore;
import elki.database.ids.DBIDFactory;
import elki.database.ids.DBIDIter;
import elki.database.ids.DBIDRange;
import elki.database.ids.DBIDUtil;
import elki.database.relation.*;
import elki.datasource.ArrayAdapterDatabaseConnection;
import elki.datasource.DatabaseConnection;
import elki.math.DoubleMinMax;
import elki.outlier.OutlierAlgorithm;
import elki.result.outlier.InvertedOutlierScoreMeta;
import elki.result.outlier.OutlierResult;
import elki.result.outlier.OutlierScoreMeta;
import elki.utilities.datastructures.BitsUtil;
import elki.utilities.optionhandling.OptionID;
import elki.utilities.optionhandling.Parameterizer;
import elki.utilities.optionhandling.constraints.CommonConstraints;
import elki.utilities.optionhandling.parameterization.Parameterization;
import elki.utilities.optionhandling.parameters.DoubleParameter;
import elki.utilities.optionhandling.parameters.IntParameter;
import elki.utilities.optionhandling.parameters.RandomParameter;
import elki.utilities.random.RandomFactory;

public class OutRankS1HDBSCAN implements OutlierAlgorithm {
  /**
   * Clustering algorithm.
   */
  private HDBSCANHierarchyExtraction hdbscanExtraction;

  /**
   * Weighting parameter of size vs. dimensionality score.
   */
  double alpha;

  /**
   * Number of random subspaces.
   */
  int subspaces;

  /**
   * Random generator
   */
  private RandomFactory rnd;

  /**
   * Constructor with parameters.
   * 
   * @param hdbscanExtraction HDBSCAN* extraction to use
   */
  public OutRankS1HDBSCAN(HDBSCANHierarchyExtraction hdbscanExtraction, double alpha, int subspaces, RandomFactory rnd) {
    super();
    this.hdbscanExtraction = hdbscanExtraction;
    this.alpha = alpha;
    this.subspaces = subspaces;
    this.rnd = rnd;
  }

  public OutlierResult run(Database db, Relation<? extends NumberVector> relation) {
    final int n = relation.size();
    final int dim = RelationUtil.dimensionality(relation);
    SimpleTypeInformation<NumberVector> type;
    double[] score = new double[n];
    Arrays.fill(score, 0.);
    for(int subspace = 0; subspace < subspaces; subspace++) {
      // Features selection for subspace
      final Random random = rnd.getSingleThreadedRandom();
      int projdims = random.nextInt(dim) + 1;
      long[] subspacedims = BitsUtil.random(projdims, dim, random);
      NumericalFeatureSelection<NumberVector> projection = new NumericalFeatureSelection<>(subspacedims);
      projection.initialize(relation.getDataTypeInformation());

      // Build virtual relation
      type = VectorFieldTypeInformation.typeRequest(NumberVector.class, projdims, projdims);
      DBIDRange vids = DBIDFactory.FACTORY.generateStaticDBIDRange(1, relation.size());
      MaterializedRelation<NumberVector> vrelation = new MaterializedRelation<>(type, vids);
      for(DBIDIter it = relation.iterDBIDs(); it.valid(); it.advance()) {
        vrelation.insert(it, projection.project(relation.get(it)));
      }

      double[][] data = RelationUtil.relationAsMatrix(vrelation, DBIDUtil.ensureArray(vrelation.getDBIDs()));
      // Adapter to load data from an existing array
      DatabaseConnection dbc = new ArrayAdapterDatabaseConnection(data);
      // Create a database (which may contain multiple relations!)
      Database database = new StaticArrayDatabase(dbc);
      // Load the data into the database (do NOT forget to initialize...)
      database.initialize();

      // Run the clustering algorithm
      Clustering<?> clustering = hdbscanExtraction.autorun(database);

      int maxdim = projdims, maxsize = 0;
      // Find maximum dimensionality and cluster size
      for(Cluster<?> cluster : clustering.getAllClusters()) {
        maxsize = Math.max(maxsize, cluster.size());
      }

      // Iterate over all clusters:
      for(Cluster<?> cluster : clustering.getAllClusters()) {
        double relsize = cluster.size() / (double) maxsize;
        double reldim = projdims / (double) maxdim;
        // Process objects in the cluster
        for(DBIDIter iter = cluster.getIDs().iter(); iter.valid(); iter.advance()) {
          final int offset = DBIDUtil.asInteger(iter) - 1 - (n * (subspace + 1));
          double oldscore = score[offset];
          double newscore = oldscore + (alpha * relsize + (1 - alpha) * reldim);
          score[offset] = newscore;
        }
      }
    }

    DoubleMinMax minmax = new DoubleMinMax();
    type = VectorFieldTypeInformation.typeRequest(NumberVector.class, dim, dim);
    WritableDoubleDataStore meanscore = DataStoreUtil.makeDoubleStorage(db.getRelation(type).getDBIDs(), DataStoreFactory.HINT_HOT);
    for(DBIDIter iter = relation.iterDBIDs(); iter.valid(); iter.advance()) {
      double newscore = score[DBIDUtil.asInteger(iter) - 1] / (double) subspaces;
      meanscore.put(iter, newscore);
      minmax.put(newscore);
    }

    DoubleRelation scoreResult = new MaterializedDoubleRelation("OutRank-S1(HDBSCAN)", relation.getDBIDs(), meanscore);
    OutlierScoreMeta meta = new InvertedOutlierScoreMeta(minmax.getMin(), minmax.getMax(), 0, Double.POSITIVE_INFINITY);
    return new OutlierResult(meta, scoreResult);
  }

  @Override
  public TypeInformation[] getInputTypeRestriction() {
    return TypeUtil.array(TypeUtil.NUMBER_VECTOR_FIELD);
  }

  /**
   * Parameterization class.
   * 
   * @author Braulio V.S. Vinces
   */
  public static class Par implements Parameterizer {

    /**
     * Alpha parameter for S1
     */
    public static final OptionID ALPHA_ID = new OptionID("outrank.s1.alpha", "Alpha parameter for S1 score.");

    public static final OptionID SUBSPACES_ID = new OptionID("outrank.s1.subspaces", "Number of random subspaces.");

    /**
     * Parameter to specify the seed to initialize Random.
     */
    public static final OptionID SEED_ID = new OptionID("outrank.s1.seed", "The seed to use for initializing Random.");

    /**
     * Clustering algorithm to run.
     */
    protected HDBSCANHierarchyExtraction hdbscanExtraction;

    /**
     * Alpha parameter to balance parameters
     */
    protected double alpha = 0.25;

    protected int subspaces = 100;

    /**
     * Random generator
     */
    protected RandomFactory rnd;

    @Override
    public void configure(Parameterization config) {
      hdbscanExtraction = config.tryInstantiate(HDBSCANHierarchyExtraction.class);
      new DoubleParameter(ALPHA_ID, 0.25) //
          .addConstraint(CommonConstraints.GREATER_THAN_ZERO_DOUBLE) //
          .grab(config, x -> alpha = x);
      new IntParameter(SUBSPACES_ID, 100) //
          .addConstraint(CommonConstraints.GREATER_EQUAL_ONE_INT) //
          .grab(config, x -> subspaces = x);
      new RandomParameter(SEED_ID).grab(config, x -> this.rnd = x);
    }

    @Override
    public OutRankS1HDBSCAN make() {
      return new OutRankS1HDBSCAN(hdbscanExtraction, alpha, subspaces, rnd);
    }
  }
}
