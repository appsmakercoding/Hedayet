"""flutter create-এর পরে Android প্রজেক্টে নোটিফিকেশন ও অ্যালার্মের সেটিং বসায়।
কোনো ধাপ না মিললে বিল্ড ইচ্ছা করেই ব্যর্থ হয়, যাতে সমস্যা চোখে পড়ে।"""
import pathlib
import re

# ---------- AndroidManifest ----------
manifest = pathlib.Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text(encoding='utf-8')

permissions = '''    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
'''

receivers = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''

if 'POST_NOTIFICATIONS' not in text:
    text = text.replace('<application', permissions + '    <application', 1)
if 'ScheduledNotificationReceiver' not in text:
    text = text.replace('</application>', receivers + '    </application>', 1)
# লোকেশনের (GPS) অনুমতি: নিষিদ্ধ সময় ও ওয়াক্ত হিসাবের জন্য
for _perm in ('ACCESS_COARSE_LOCATION', 'ACCESS_FINE_LOCATION'):
    if _perm not in text:
        text = text.replace(
            '<application',
            '    <uses-permission android:name="android.permission.%s"/>\n    <application' % _perm,
            1,
        )
assert 'ACCESS_FINE_LOCATION' in text, 'লোকেশনের অনুমতি বসেনি'

manifest.write_text(text, encoding='utf-8')
assert 'ScheduledNotificationBootReceiver' in manifest.read_text(encoding='utf-8'), 'Manifest patch failed'
print('Manifest patched')

# ---------- ProGuard নিয়ম (Gson TypeToken ও নোটিফিকেশন প্যাকেজ রক্ষা) ----------
pathlib.Path('android/app/proguard-rules.pro').write_text(
    '-keepattributes Signature\n'
    '-keepattributes *Annotation*\n'
    '-keep class com.dexterous.flutterlocalnotifications.** { *; }\n'
    '-keep class com.google.gson.reflect.TypeToken { *; }\n'
    '-keep class * extends com.google.gson.reflect.TypeToken\n',
    encoding='utf-8',
)

# ---------- app/build.gradle (Groovy বা Kotlin) ----------
groovy = pathlib.Path('android/app/build.gradle')
kts = pathlib.Path('android/app/build.gradle.kts')

if groovy.exists():
    path, is_kts = groovy, False
elif kts.exists():
    path, is_kts = kts, True
else:
    raise SystemExit('app build.gradle পাওয়া যায়নি')

s = path.read_text(encoding='utf-8')
if 'coreLibraryDesugaring' not in s:
    if is_kts:
        s = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', s, count=1)
        s = re.sub(r'defaultConfig\s*\{', 'defaultConfig {\n        multiDexEnabled = true', s, count=1)
        release_extra = ('\n            isMinifyEnabled = false\n            isShrinkResources = false'
                         '\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")')
        s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
    else:
        s = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        coreLibraryDesugaringEnabled true', s, count=1)
        s = re.sub(r'defaultConfig\s*\{', 'defaultConfig {\n        multiDexEnabled true', s, count=1)
        release_extra = ('\n            minifyEnabled false\n            shrinkResources false'
                         "\n            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'")
        s += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'\n}\n"
    s = re.sub(r'(buildTypes\s*\{\s*release\s*\{)', lambda m: m.group(1) + release_extra, s, count=1)
    path.write_text(encoding='utf-8', data=s)

final = path.read_text(encoding='utf-8')
assert ('minifyEnabled false' in final) or ('isMinifyEnabled = false' in final), 'minify বন্ধ করা যায়নি'
assert 'coreLibraryDesugaring' in final, 'desugaring বসেনি'
print(path.name, 'patched')
print('----- patched', path.name, '-----')
print(final)


# ---------- Lint-vital বন্ধ (প্লাগিনের lint ক্র্যাশ করলেও APK বিল্ড যেন থেমে না যায়) ----------
root_kts = pathlib.Path('android/build.gradle.kts')
root_groovy = pathlib.Path('android/build.gradle')
if root_kts.exists():
    rp = root_kts
    block = (
        '\n// hedayet: lintVital বন্ধ\n'
        'subprojects {\n'
        '    tasks.configureEach {\n'
        '        if (name.startsWith("lintVital")) {\n'
        '            enabled = false\n'
        '        }\n'
        '    }\n'
        '}\n'
    )
elif root_groovy.exists():
    rp = root_groovy
    block = (
        '\n// hedayet: lintVital বন্ধ\n'
        'subprojects {\n'
        '    tasks.configureEach { task ->\n'
        "        if (task.name.startsWith('lintVital')) {\n"
        '            task.enabled = false\n'
        '        }\n'
        '    }\n'
        '}\n'
    )
else:
    rp = None
if rp is not None:
    rt = rp.read_text(encoding='utf-8')
    if 'hedayet: lintVital' not in rt:
        rp.write_text(rt + block, encoding='utf-8')
    print(rp.name, 'lintVital disabled')
    
