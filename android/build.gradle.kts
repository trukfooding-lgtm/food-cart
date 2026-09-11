allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val android = project.extensions.findByName("android") ?: return@afterEvaluate
            for (m in android.javaClass.methods) {
                if (m.name in listOf("setCompileSdk", "setCompileSdkVersion", "compileSdkVersion") && m.parameterCount == 1) {
                    try {
                        m.invoke(android, 36)
                        break
                    } catch (_: Exception) {}
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}