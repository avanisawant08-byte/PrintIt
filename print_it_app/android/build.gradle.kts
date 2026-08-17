allprojects {
    repositories {
        google()
        mavenCentral()
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
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val setCompileSdk = android.javaClass.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterTypes.size == 1 && it.parameterTypes[0].name == "int" }
                setCompileSdk?.invoke(android, 36)
                
                val compileSdkVersion = android.javaClass.methods.firstOrNull { it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0].name == "int" }
                compileSdkVersion?.invoke(android, 36)
            } catch (e: Exception) {}
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
