#!/usr/bin/env node

const Bluebird = require('bluebird');
const csv = require('fast-csv');
const fs = require('fs');
const path = require('path');
const _ = require('lodash');

const TESTS = [
  'BurstLvl1',
  'BurstLvl2',
  'BurstLvl3',
  'ConcurrentIncreasingLoadLvl1',
  'ConcurrentIncreasingLoadLvl2',
  'ConcurrentIncreasingLoadLvl3',
  'IncreasingCPULoadLvl1',
  'IncreasingCPULoadLvl2',
  'IncreasingCPULoadLvl3',
  'IncreasingMemLoadLvl1',
  'IncreasingMemLoadLvl2',
  'IncreasingMemLoadLvl3',
];

const PROVIDERS = [
  'aws',
  'azure',
  'knative',
  'openfaas',
  'kubeless',
  'fission',
];

const OUTPUT_DIR = 'outputs';
const NUM_ITERS = 1 // TODO (Sam): Set back to 10

function getMemory(provider, f) {
  if (provider == 'azure') {
    return 0;
  }

  let memory = f.memorySize;

  if (_.isEmpty(memory)) {
    memory = _.chain(f.functionName)
      .split("-")
      .last()
      .value();
  }

  return parseInt(memory.replace(/\D/g, ''), 10);
}

function readResults(testName, provider, filename, id) {
  const rawData = fs.readFileSync(path.join(testName, provider, filename));
  const results = JSON.parse(rawData);
  const rows = _.chain(results.functions)
    .flatMap((f) => {
      const memory = getMemory(provider, _.pick(f, ['functionName', 'memorySize']));
      return _.chain(f.results)
        .uniqBy('id')
        .map(entry => _.assign({}, entry, {
          duration: entry.duration < 0 ? 0 : entry.duration,
          memory,
        }))
        .value();
    })
    .value();

  return new Promise((resolve, reject) => {
    if (!fs.existsSync(OUTPUT_DIR)) {
      fs.mkdirSync(OUTPUT_DIR);
    }

    const outputFile = path.join(OUTPUT_DIR, `${testName}_${provider}_${id}.csv`);
    fs.closeSync(fs.openSync(outputFile, 'w'));

    csv.writeToPath(outputFile, rows, { headers: true })
      .on('error', reject)
      .on('finish', () => {
        // console.log('Wrote', outputFile);
        resolve();
      });
  });
}

async function readProvider(testName, provider) {
  const pathToProvider = path.join(testName, provider);
  const filenames = fs.readdirSync(pathToProvider);

  // Read only the last NUM_ITERS results
  const filteredFilenames = _.chain(filenames.sort())
    .filter(filename => _.startsWith(filename, 'results'))
    .takeRight(NUM_ITERS)
    .value();

  await Bluebird.map(filteredFilenames, (filename, i) => {
    try {
      return readResults(testName, provider, filename, i + 1);
    } catch (err) {
      console.log('Failed', { testName, provider, filename, err });
      return Promise.resolve();
    }
  });
}

async function readTest(testName) {
  await Bluebird.map(PROVIDERS, async (provider) => {
    if (!fs.existsSync(path.join(testName, provider))) {
      return;
    }

    await readProvider(testName, provider);
  })
}

async function readTests() {
  await Bluebird.map(TESTS, async (testName) => {
    if (!fs.existsSync(testName)) {
      return;
    }

    await readTest(testName);
  });
  console.log('Done!');
}

readTests();
