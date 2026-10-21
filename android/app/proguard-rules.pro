# Flutter's Gradle plugin minifies release builds with R8 and appends this
# file to its own rules whenever it exists (nothing in build.gradle.kts has
# to name it).
#
# Keep androidx.activity's EdgeToEdge.enable (MainActivity.enableEdgeToEdge())
# as a real call in the release build. R8 otherwise inlines it into
# MainActivity.onCreate and renames the class, and the Play Console's
# edge-to-edge check — a static scan for that call — then reports
# "Edge-to-edge may not display for all users" on a build that is edge to
# edge on every version. A kept method is never inlined.
-keep class androidx.activity.EdgeToEdge { *; }
