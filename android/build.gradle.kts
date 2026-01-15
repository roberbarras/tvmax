import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.jvm.toolchain.JavaLanguageVersion

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
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

subprojects {
    project.pluginManager.withPlugin("java") {
        project.extensions.configure(JavaPluginExtension::class.java) {
             // Toolchain removed to allow Gradle to use the daemon's JDK (Java 21)
             // sourceCompatibility/targetCompatibility below handles Java 17 bytecode generation
        }
    }

    project.pluginManager.withPlugin("com.android.library") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        // Workaround for ffmpeg_kit_flutter_new missing namespace
        if (project.name == "ffmpeg_kit_flutter_new") {
             android.namespace = "com.arthenica.ffmpegkit.flutter"
        }
        
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
