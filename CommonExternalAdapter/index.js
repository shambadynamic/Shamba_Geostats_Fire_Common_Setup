const express = require('express');
const app = express();
const bodyParser = require('body-parser')
const cors = require('cors')
const createRequest = require('./app').createRequest
const retrieve_cid_urls_list = require('./app').retrieve_cid_urls_list
const callApi = require('./app').retrieve_cid_urls_list

const PORT = 5555;

app.use(bodyParser.json())
app.use(cors())
app.options('*', cors())

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

app.get('/', (req, res) => {
    retrieve_cid_urls_list((result) => {
        res.json(result);
    });

})

app.post('/', (req, res) => {
    if (typeof(req.body["data"]) == "string") {
        req.body["data"] = JSON.parse(req.body["data"]);
    }
    console.log('POST Data: ', req.body)
    createRequest(req.body, (status, result) => {
        console.log('Result: ', result)
        res.status(status).json(result)
    })
})

module.exports = {
    app
};