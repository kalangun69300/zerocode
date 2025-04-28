FROM openjdk:25-bookworm

WORKDIR /app 

COPY zerocode-maven-archetype/target/zerocode-maven-archetype-1.3.46-SNAPSHOT.jar zerocode-maven-archetype-1.3.46-SNAPSHOT.jar

ENTRYPOINT [ "java", "-jar", "zerocode-maven-archetype-1.3.46-SNAPSHOT.jar" ]
