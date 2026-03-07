#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

const nextVersion = process.argv[2];
if (!nextVersion) {
  console.error('Missing semantic-release version argument.');
  process.exit(1);
}

const pubspecPath = path.resolve(process.cwd(), 'pubspec.yaml');
const pubspec = fs.readFileSync(pubspecPath, 'utf8');
const versionLinePattern = /^version:\s*(\d+\.\d+\.\d+)(\+\d+)?\s*$/m;
const match = pubspec.match(versionLinePattern);

if (!match) {
  console.error('Could not find a valid version line in pubspec.yaml');
  process.exit(1);
}

const buildSuffix = match[2] || '+1';
const updatedPubspec = pubspec.replace(
  versionLinePattern,
  `version: ${nextVersion}${buildSuffix}`,
);

fs.writeFileSync(pubspecPath, updatedPubspec, 'utf8');
console.log(`Updated pubspec.yaml to version ${nextVersion}${buildSuffix}`);
