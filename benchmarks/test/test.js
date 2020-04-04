const axios = require('axios');
const Bluebird = require('bluebird');
const moment = require('moment');
const _ = require('lodash');

const URL = 'https://jrj90cyc01.execute-api.eu-central-1.amazonaws.com/dev/float';
const REQ_CONFIG = {
  params: {
    n: 1000,
  },
};
const NUM_REQS = 3;
const CONCURRENT = true;

async function invokeFunction() {
  try {
    const start = moment();
    const res = await axios.get(URL, REQ_CONFIG);
    const end = moment();
    return {
      result: res.data,
      latency: end.diff(start),
    };
  } catch (err) {
    if (err.response) {
      console.log(err.response.status);
      console.log(err.response.data);
    } else {
      console.log(err.message);
    }
    return null;
  }
}

async function test() {
  if (CONCURRENT) {
    const out = await Bluebird.map(_.range(NUM_REQS), invokeFunction);
    console.log(out);
  } else {
    
  }
}

test();
