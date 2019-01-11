const fetch = require('node-fetch');
const AWS = require('aws-sdk');

class SolrMetrics {
  constructor(url, region) {
    this.metrics = [];
    this.publishedMetrics = [];
    this.region = region;
    this.solrUrl = url;
  }

  get(path) {
    return new Promise((resolve, reject) => {
      fetch(`${this.solrUrl}/${path}`)
        .then(res => res.json())
        .then(json => resolve(json))
        .catch(error => reject(error));
    });
  }

  add(name, value, dimensions) {
    var newMetric = { MetricName: name, Value: value, Unit: 'Count', Dimensions: [] };
    for (var dim in dimensions) {
      newMetric.Dimensions.push({ Name: dim, Value: dimensions[dim] });
    }
    this.metrics.push(newMetric);
    if (this.metrics.length == 20) {
      this.flush();
    }
    return this.metrics;
  }

  flush() {
    if (this.metrics.length > 0) {
      this.post();
      this.publishedMetrics = this.publishedMetrics.concat(this.metrics);
      this.metrics = [];
    }
  }

  post() {
    return new Promise((resolve, reject) => {
      var client = new AWS.CloudWatch({ region: this.region });
      client.putMetricData({ Namespace: 'NUL/Solr', MetricData: this.metrics }, (err, data) => {
        if (err) reject(err);
        else     resolve(data);
      })
    })
  }
}

module.exports = SolrMetrics;