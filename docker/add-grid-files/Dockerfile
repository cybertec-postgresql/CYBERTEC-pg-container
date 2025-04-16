ARG CONTAINERIMAGE

FROM ${CONTAINERIMAGE}

# Grid-Files ins Image kopieren
COPY grid-files/ /proj/grids/

# Setze ein Arbeitsverzeichnis
WORKDIR /proj

CMD ["/bin/sh", "-c", "cp -r /proj/grids/* /proj-target/"]


#additionalVolumes:
#     - mountPath: /home/postgres/.local/share/proj
#       name: proj-grids
#       targetContainers:
#         - postgres
#       volumeSource:
#         emptyDir: {}
#   initContainers:
#     - image: 'docker.io/schmaetz/proj:test-v0.0.3'
#       name: proj
#       volumeMounts:
#         - mountPath: /proj-target
#           name: proj-grids