sample-diff
====================================
"Sample diff" diffs two big files with a few of them, and require only two IO.
The sample algorithm is called [Reservoir sampling](http://en.wikipedia.org/wiki/Reservoir_sampling).


Example
------------------------------------
```javascript
var SampleDiff = require('sample-diff');

var opts = {
  'fetch_item_id_func' : function(line1) {
       return parseInt(line1.match(/uid\": ?([0-9]+)[,\}]/)[1]);
  },
  'diff_items_func'   : function(a, b) {
       console.log(difflet.compare(a, b), "\n")
   },
   'data_normalization_func'  : function(line1) {
       item1 = process(line1);
       return item1;
   },
   'filter_func' : function(line1) {
       return false;
   }
};

var checker = SampleDiff(fileA, fileB, sample_count, opts);

checker.run(function(result) {
  // process result
});
```

INSTALL
------------------------------------
```bash
npm install sample-diff -g --verbose
```

Development & Test
------------------------------------
```bash
# install node and npm
npm install --global --verbose grunt-cli
npm install --global --verbose grunt-contrib-coffee
npm install --verbose # install deps
grunt --verbose # compile coffee scripts

npm test
```

License
------------------------------------
MIT. David Chen @ 17zuoye.
