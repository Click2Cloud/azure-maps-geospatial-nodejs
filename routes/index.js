var express = require('express');
var router = express.Router();

var sql = require("mssql");
const dotenv = require('dotenv');
dotenv.config();

// config for your database
var db = {
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSSWORD,
    server: process.env.DB_SERVER, 
    database: process.env.DB_DATABASE 
};

/* GET home page. */
router.get('/', function(req, res, next) {
    res.render('index', { title: 'Express' });
});

router.get('/data', function(req, res, next) {
    try {
        sql.connect(db, function (err) {
        
            if (err) console.log(err);

            // create Request object
            var request = new sql.Request();
            
            // query to the database and get the records
            request.query('EXEC [GetHurricaneDataFlorida]', function (err, recordset) {
                
                if (err) console.log(err)

                // send records as a response
                res.send(recordset.recordset[0]);
                
            });
        });
    }
    catch(e) {
        console.log(e)
    }
});


module.exports = router;
