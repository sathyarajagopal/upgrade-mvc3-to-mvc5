#Upgrade from MVC 3.0.0.1 to MVC 5.2.3.0
This package upgrades your web application from MVC 3 to MVC 5. Also please note that Microsoft recommends bin deployment of MVC 5 dlls.

#Installation steps
Go to Visual Studio PMC and type the below command:
Install-Package UpgradeMvc3ToMvc5 -Version 1.0.0

#Summary of execution
#Target Framework of the project will be switched to 4.5.2
Old 4.0
New 4.5.2

#DLLs - The below dll references will be updated
#System.Web.Helpers
Old 1.0.0.0
New 3.0.0.0
#System.Web.Mvc
Old 3.0.0.1
New 5.2.3.0
#System.Web.Razor
Old 1.0.0.0
New 3.0.0.0
#System.Web.Webpages
Old 1.0.0.0
New 3.0.0.0
#System.Web.Webpages.Deployment
Old 1.0.0.0
New 3.0.0.0
#System.Web.Webpages.Razor
Old 1.0.0.0
New 3.0.0.0

#ProjectTypeGuids is updated
Old {E53F8FEA-EAE0-44A6-8774-FFD645390401}
New {349C5851-65DF-11DA-9384-00065B846F21}

#web.config root below change is done
Old <add key="webpages:Version" value="1.0.0.0" />
New <add key="webpages:Version" value="3.0.0.0" />

#web.config view below changes are done
Old System.Web.WebPages.Razor 1.0.0.0
New System.Web.WebPages.Razor 3.0.0.0
Old System.Web.Mvc 3.0.0.1
New System.Web.Mvc 5.2.3.0

#Reinstall any existing nuget packages that are targetting .Net Framework 4.0 so that it will target .Net Framework 4.5.2

#The package is generated using the below command
nuget pack UpgradeMvc3ToMvc5