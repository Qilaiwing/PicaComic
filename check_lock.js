const fs = require('fs');
const content = fs.readFileSync('pubspec.lock', 'utf8');
const match = content.match(/workmanager:[\s\S]*?version: "(.*?)"/);
console.log('workmanager locked version:', match ? match[1] : 'not found');
