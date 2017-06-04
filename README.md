what is eggX ?

eggX is a simple bash script to aid a build linux image.

1) recipes in xml
2) repo of recipes
3) build in step for repo : same project recipes can build and rebuild in different step with different configuration
4) incremental build : test a new project recipe as single and insert in repo collection
5) more light and simple to use and debug and easy to expand
6) generate for any single project the bash scripts for download, patch, configure, build ect
7) for any project can open a shell with enviroment set as request from recipes an work on the fly
8) recipes describe conf/make/install sequence order and conf/make/install parameter order.
9) for any download or build action in recipe  can insert a pre post action to call a script, source a script or immediate exec of shell code.
10) very automated build of  list of repo ( .. is repo of repo of repo....), in a xml file .
11) store all tar sources in appropriate area to off line work
12) dowload method: wget, rsync, git,svn,apt-get
13) .. to do ...


