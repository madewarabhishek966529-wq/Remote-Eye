allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all Android plugin subprojects (flutter_webrtc, mobile_scanner, etc.)
// to compile with SDK 36. Their AndroidX dependencies (fragment 1.7.1,
// core-ktx 1.13.1, activity 1.8.1, etc.) require compileSdk >= 34.
subprojects {
    afterEvaluate {
        // Override compileSdk for Library modules (plugins)
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.compileSdk = 36
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
