const { spawn } = require('child_process');

const env = {
    ...process.env,
    JAVA_HOME: 'D:\\Agent\\BuildTools\\Android\\jdk-17',
    ANDROID_HOME: 'D:\\Agent\\BuildTools\\Android\\android-sdk',
    PUB_HOSTED_URL: 'https://pub.flutter-io.cn',
    FLUTTER_STORAGE_BASE_URL: 'https://storage.flutter-io.cn',
    PATH: `D:\\Agent\\BuildTools\\flutter\\bin;C:\\Program Files\\Git\\cmd;D:\\Agent\\BuildTools\\Android\\jdk-17\\bin;D:\\Agent\\BuildTools\\Android\\android-sdk\\platform-tools;${process.env.PATH}`
};

console.log('Starting flutter build apk --debug...');
const p = spawn('D:\\Agent\\BuildTools\\flutter\\bin\\flutter.bat', ['build', 'apk', '--debug', '-v'], {
    cwd: 'D:\\Agent\\Projects\\PicaComic_MIUIX',
    env,
    shell: true
});

p.stdout.on('data', (d) => process.stdout.write(d));
p.stderr.on('data', (d) => process.stderr.write(d));
p.on('close', (c) => console.log('\nFlutter build finished with code:', c));
