# MyWeb
## iOS app that creates an interactive 3D web of a user's Facebook friends based on photo tags.

*Swift, Facebook API, SceneKit, Force Directed Graph*
 
# Motivation and Description
One weekend I grew tired of working on my KnifeLife app all day, so I decided to dig into my backlog of app ideas and pulled out this idea. I find social networks fascinating and wanted a way to view my own network through facebook. 

I used facebooks API to pull all of the tagged names in each of a user's photos and organized these names into a graph. I then created a force directed graph algorithm to spatially organize each of the names.

This was a fun project as it allowed me to use Facebook's SDK as well as Apple's underappreciated SceneKit

# Screenshots
![](https://github.com/jakecronin/MyWeb/blob/master/Images/Clean_Web_1.png =150x150)
![](https://github.com/jakecronin/MyWeb/blob/master/Images/Web_With_Names.png =150x150)

# Without Directed Graph Algorithm
![](https://github.com/jakecronin/MyWeb/blob/master/Images/Unorganized_Web.png =150x150)
