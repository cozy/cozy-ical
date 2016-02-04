var IcalParser = require('./lib/index').ICalParser,
    parser = new IcalParser();

if (typeof process.argv[2] === 'undefined') {
  console.error("Usage: node index.js file.ics");
} else {
  parser.parseFile(process.argv[2], function (err, result) {
    if (err) {
      console.error(err);
    } else {
      console.log("No error");
      console.log(result);
    }
  });
}
