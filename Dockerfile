FROM microsoft/powershell:latest

# default environment processing
#ENV SUMO_ACCESS_ID=$SUMO_ACCESS_ID
#ENV SUMO_ACCESS_KEY=$SUMO_ACCESS_KEY
ENV SUMO_DEPLOYMENT=au

# A simple script to get up to 10 collectors via the API
COPY . /home/
#RUN chmod +x /home/demo.ps1

################################################################
# importing modules takes longer if you build container lots of times
# faster to download once so can cache by docker.
RUN mkdir ./psm 
#RUN pwsh -c "Save-Module SumoLogic-Core -Path ./psm -Repository PSGallery"
RUN pwsh -c "Save-Module Pester -Path ./psm -Repository PSGallery"
#RUN pwsh -c "Install-Module Pester -Repository PSGallery"

# setup a profile to launch the module import and a connection if session=true
RUN mkdir -p /root/.config/powershell
COPY profile.ps1 /root/.config/powershell/profile.ps1
RUN chmod +x /root/.config/powershell/profile.ps1

ENTRYPOINT ["pwsh"]

# to execute your own custom script include this in the container using COPY or map a volume and modify the entrypoint e.g
# ENTRYPOINT ["pwsh","-File","/home/demo.ps1"]
