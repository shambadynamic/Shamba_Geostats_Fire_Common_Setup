const axios = require('axios')
require('dotenv').config();
const fs = require('fs');
const { Web3Storage, getFilesFromPath } = require('web3.storage');

async function retrieve_cid_urls_list(callback) {
    try {

        const token = process.env.TOKEN;
        var cid_url_list = []

        axios.get('https://api.web3.storage/user/uploads', {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            })
            .then(response => {
                var data_list = response.data
                for (var i = 0; i < data_list.length; i++) {
                    var data = data_list[i]
                    cid_url_list.push("https://dweb.link/ipfs/" + data['cid'] + "/data.json")

                }
                callback({ "urls": cid_url_list })

            }).catch(error => {
                console.error('There was an error!', error);
                callback({ "Error": error.message });
            });


    } catch (e) {
        console.error(e);
        callback({ "Error": e.message });
    }
}

const createRequest = (input, callback) => {

    const jobRunID = input['id']
    var tx_hash = ''
    var contract_address = ''
    var operator_address = ''
    var agg_x = ''
    var endpoint = 'fire-analysis'

    if ('tx_hash' in input) {
        tx_hash = input['tx_hash']
    }

    if ('contract_address' in input) {
        contract_address = input['contract_address']
    }

    if ('operator_address' in input) {
        operator_address = input['operator_address']
    }


    const dataset_code = input['data']['dataset_code']
    const selected_band = input['data']['selected_band']
    const geometry = input['data']['geometry']
    const start_date = input['data']['start_date']
    const end_date = input['data']['end_date']
    const image_scale = input['data']['image_scale']

    if ('agg_x' in input['data']) {
        agg_x = input['data']['agg_x']
        endpoint = 'statistics'
    }

    const url = `https://shamba-gateway-staging-2ycmet71.ew.gateway.dev/geoapi/v1/${endpoint}`

    const data = {
        dataset_code,
        selected_band,
        geometry,
        start_date,
        end_date,
        image_scale,
    }

    axios
        .post(url, data)
        .then(res => {
            if (res.status == 200) {
                var datetime = new Date();

                res.data.jobRunID = jobRunID
                res.data.statusCode = res.status
                var final_result = ''
                if (endpoint == 'statistics') {
                    final_result = res.data['data'][agg_x] * (10 ** 18)
                    res.data.data = {
                        [agg_x]: final_result,
                        "result": final_result
                    }

                } else {
                    final_result = []
                    var agg_fire_detected = res.data['data']['detection']
                    for (var i = 0; i < agg_fire_detected.length; i++) {
                        if (agg_fire_detected[i]['fire_detected'] == true) {
                            final_result.push(1)
                        } else {
                            final_result.push(9)
                        }
                    }
                }

                res.data.result = final_result


                delete res.data.success
                delete res.data.error
                delete res.data.data_token
                delete res.data.duration


                var web3_json_data = {
                    "request": {
                        "dataset_code": dataset_code,
                        "selected_band": selected_band,
                        "geometry": geometry,
                        "start_date": start_date,
                        "end_date": end_date,
                        "image_scale": image_scale
                    },
                    "response": {
                        "datetime": datetime.toISOString(),
                        "result": final_result,
                        "contract_address": contract_address,
                        "operator_address": operator_address,
                        "tx_hash": tx_hash
                    }
                }

                if (endpoint == 'statistics') {
                    web3_json_data.request['agg_x'] = agg_x
                    web3_json_data.response[agg_x] = final_result
                }

                path = "/tmp/data.json"
                const jsonContent = JSON.stringify(web3_json_data);

                if (fs.existsSync(path)) {
                    fs.readFile(path, (err, fileData) => {
                        var data = JSON.parse(fileData.toString());
                        if (web3_json_data.response.tx_hash !== data.response.tx_hash) {
                            try {
                                fs.writeFile(path, jsonContent, async function(err) {
                                    if (err) {
                                        console.log("An error occured while writing JSON Object to File.");
                                        console.log(err);
                                        var res = {
                                            "status": 403,
                                            "data": {
                                                "jobRunID": jobRunID,
                                                "status": "errored",
                                                "error": {
                                                    "name": "Unable to write data to the json file",
                                                },
                                                "statusCode": 403
                                            }

                                        }
                                        callback(res.status, res.data)

                                    } else {
                                        console.log("JSON file has been saved.");
                                        const token = process.env.TOKEN;

                                        console.log(token);

                                        const storage = new Web3Storage({ token })

                                        const file = await getFilesFromPath(path);

                                        const cid = await storage.put(file)
                                        console.log('Content added with CID:', cid)

                                        var res = {
                                            "status": 200,
                                            "data": {
                                                "jobRunID": jobRunID,
                                                "status": "success",
                                                "result": { "cid": cid, "result": final_result },
                                                "message": `Data successfully uploaded to https://dweb.link/ipfs/${cid}`,
                                                "statusCode": 200
                                            }
                                        }
                                        callback(res.status, res.data)

                                    }
                                });
                            } catch (e) {
                                var res = {
                                    "status": 405,
                                    "data": {
                                        "jobRunID": jobRunID,
                                        "status": "errored",
                                        "error": {
                                            "name": "Unable to upload data to web3 store",
                                        },
                                        "statusCode": 405
                                    }

                                }

                                callback(res.status, res.data)
                            }

                        } else {
                            if (fs.existsSync(path)) {
                                retrieve_cid_urls_list((data) => {
                                    console.log(data['urls']);

                                    var urls = data['urls']
                                    var json_data_url = urls[0].toString().replace('/data.json', '')
                                    var url_arr = json_data_url.split('/')
                                    var cid_value = url_arr[url_arr.length - 1]

                                    var res = {
                                        "status": 200,
                                        "data": {
                                            "jobRunID": jobRunID,
                                            "status": "success",
                                            "result": { "cid": cid_value, "result": final_result },
                                            "message": `Data successfully uploaded to ${json_data_url}`,
                                            "statusCode": 200
                                        }

                                    }
                                    callback(res.status, res.data)
                                });

                            } else {
                                try {

                                    fs.writeFile(path, jsonContent, async function(err) {
                                        if (err) {
                                            console.log("An error occured while writing JSON Object to File.");
                                            console.log(err);
                                            var res = {
                                                "status": 403,
                                                "data": {
                                                    "jobRunID": jobRunID,
                                                    "status": "errored",
                                                    "error": {
                                                        "name": "Unable to write data to the json file",
                                                    },
                                                    "statusCode": 403
                                                }

                                            }

                                            callback(res.status, res.data)


                                        } else {
                                            console.log("JSON file has been saved.");
                                            const token = process.env.TOKEN;

                                            console.log(token);

                                            const storage = new Web3Storage({ token })

                                            const file = await getFilesFromPath(path);

                                            const cid = await storage.put(file)
                                            console.log('Content added with CID:', cid)



                                            var res = {
                                                "status": 200,
                                                "data": {
                                                    "jobRunID": jobRunID,
                                                    "status": "success",
                                                    "result": { "cid": cid, "result": final_result },
                                                    "message": `Data successfully uploaded to https://dweb.link/ipfs/${cid}`,
                                                    "statusCode": 200
                                                }

                                            }

                                            callback(res.status, res.data)

                                        }
                                    });
                                } catch (e) {
                                    var res = {
                                        "status": 405,
                                        "data": {
                                            "jobRunID": jobRunID,
                                            "status": "errored",
                                            "error": {
                                                "name": "Unable to upload data to web3 store",
                                            },
                                            "statusCode": 405
                                        }

                                    }

                                    callback(res.status, res.data)
                                }
                            }
                        }

                    });
                } else {
                    console.log('here')
                    try {

                        fs.writeFile(path, jsonContent, async function(err) {
                            if (err) {
                                console.log("An error occured while writing JSON Object to File.");
                                console.log(err);
                                var res = {
                                    "status": 403,
                                    "data": {
                                        "jobRunID": jobRunID,
                                        "status": "errored",
                                        "error": {
                                            "name": "Unable to write data to the json file",
                                        },
                                        "statusCode": 403
                                    }

                                }

                                callback(res.status, res.data)


                            } else {
                                console.log("JSON file has been saved.");
                                const token = process.env.TOKEN;

                                console.log(token);

                                const storage = new Web3Storage({ token })

                                const file = await getFilesFromPath(path);

                                const cid = await storage.put(file)
                                console.log('Content added with CID:', cid)



                                var res = {
                                    "status": 200,
                                    "data": {
                                        "jobRunID": jobRunID,
                                        "status": "success",
                                        "result": { "cid": cid, "result": final_result },
                                        "message": `Data successfully uploaded to https://dweb.link/ipfs/${cid}`,
                                        "statusCode": 200
                                    }

                                }

                                callback(res.status, res.data)

                            }
                        });
                    } catch (e) {
                        var res = {
                            "status": 405,
                            "data": {
                                "jobRunID": jobRunID,
                                "status": "errored",
                                "error": {
                                    "name": "Unable to upload data to web3 store",
                                },
                                "statusCode": 405
                            }

                        }

                        callback(res.status, res.data)
                    }
                }

            } else {
                res.data = {
                    "jobRunID": [jobRunID],
                    "status": "errored",
                    "error": {
                        "name": "AdapterError",
                    },
                    "statusCode": [res.status]
                }
                callback(res.status, res.data)

            }
            console.log(`statusCode: ${res.status}`)


        })
        .catch(error => {
            console.error(error)
            var res = {
                "status": 400,
                "data": {
                    "jobRunID": jobRunID,
                    "status": "errored",
                    "error": {
                        "name": "AdapterError",
                    },
                    "statusCode": 400
                }

            }

            callback(res.status, res.data)
        })

}


module.exports.createRequest = createRequest
module.exports.retrieve_cid_urls_list = retrieve_cid_urls_list