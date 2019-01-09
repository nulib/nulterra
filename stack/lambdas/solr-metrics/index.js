const SolrMetrics = require('./lib/solr_metrics.js');

async function collectMetrics(solrUrl, region) {
  var metrics = new SolrMetrics(solrUrl, region);
  var cluster = await metrics.get('admin/collections?action=CLUSTERSTATUS');

  for (var collectionName in cluster.cluster.collections) {
    var collectionInfo = cluster.cluster.collections[collectionName];
    var collection = await metrics.get(`${collectionName}/select?q=*:*&rows=0&facet=on&facet.field=has_model_ssim`);
    var docCount = collection.response.numFound;
    metrics.add('DocumentCount', docCount, { Collection: collectionName });

    var facets = collection.facet_counts.facet_fields.has_model_ssim.slice(0);
    while (facets.length > 0) { 
      var [modelName, modelCount] = facets.splice(0,2);
      if (! modelName.match(/^(Hydra|ActiveFedora)::/)) {
        metrics.add('DocumentCount', modelCount, { Collection: collectionName, Model: modelName });
      }
    }

    for (var shardName in collectionInfo.shards) {
      var shardInfo = collectionInfo.shards[shardName];
      var replicaCount = Object.keys(shardInfo.replicas).length;
      metrics.add('ActiveReplicaCount', replicaCount, { Collection: collectionName, Shard: shardName });
    }
  }

  return metrics;
}

function handler(_event, context, callback) {
  var region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];
  collectMetrics(process.env.SolrUrl, region)
    .then(metrics => {
      metrics.post();
      callback(null, metrics.metrics);
    })
    .catch(err => {
      console.log(err);
      callback(err);
    });
}

module.exports = { handler }
