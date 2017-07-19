# Runs every time a package is installed in a project
param($installPath, $toolsPath, $package, $project)
# $installPath is the path to the folder where the package is installed.
# $toolsPath is the path to the tools directory in the folder where the package is installed.
# $package is a reference to the package object.
# $project is a reference to the project the package was installed to.

try
{
    # Save project if any unsaved changes are pending
    $project.Save()

    # Get project directory
    $projectDirectory = [System.IO.Path]::GetDirectoryName($project.FullName)

    # Load project XML
    $projectXml = [xml](get-content $project.FullName)

    # Get project namespace
    $nameSpace = $projectXml.project.xmlns
    [System.Xml.XmlNamespaceManager] $nameSpaceManager = $projectXml.nametable
    $nameSpaceManager.AddNamespace('mvc3', $nameSpace)

    $assemblyBindingNameSpace = "urn:schemas-microsoft-com:asm.v1"

    $nameSpaceManager.AddNamespace('rootConfig', $assemblyBindingNameSpace)

    #Uninstall MVC 3 and its dependencies in order
    #Uninstall-Package Microsoft.AspNet.Mvc -Version 3.0.50813.1
    #Uninstall-Package Microsoft.AspNet.Webpages -Version 3.2.3
    #Uninstall-Package Microsoft.AspNet.Razor -Version 3.2.3
    #Uninstall-Package Microsoft.Web.Infrastructure -Version 1.0.0

    # Change project TargetFrameworkVersion from 4.0 to 4.5.2
    $configContent = [System.IO.File]::ReadAllText($project.FullName);
    $configContent = $configContent.Replace('<TargetFrameworkVersion>v4.0</TargetFrameworkVersion>', '<TargetFrameworkVersion>v4.5.2</TargetFrameworkVersion>');
    [System.IO.File]::WriteAllText($project.FullName, $configContent);

    #Install MVC 5
    #Install-Package Microsoft.AspNet.Mvc -Version 5.2.3

    # Iterate through each web.config and make necessary changes
    $projectXml.DocumentElement.SelectNodes("//mvc3:Content[contains(translate(@Include,'WEBCONFIG','webconfig'),'web.config')]", $nameSpaceManager) | ForEach-Object { $config = $projectDirectory + "\" + $_.Include; $configContent = [System.IO.File]::ReadAllText($config); $configContent = $configContent.Replace('System.Web.Mvc, Version=3.0.0.1', 'System.Web.Mvc, Version=5.2.3.0'); $configContent = $configContent.Replace('System.Web.WebPages, Version=1.0.0.0', 'System.Web.WebPages, Version=3.0.0.0'); $configContent = $configContent.Replace('System.Web.Helpers, Version=1.0.0.0', 'System.Web.Helpers, Version=3.0.0.0'); $configContent = $configContent.Replace('System.Web.WebPages.Razor, Version=1.0.0.0', 'System.Web.WebPages.Razor, Version=3.0.0.0'); [System.IO.File]::WriteAllText($config, $configContent); }

    $rootConfigPath = $projectDirectory + "\web.config"
    $rootConfig = [xml](get-content $rootConfigPath)

    # Changing root web.config webpages version
    $rootConfig.DocumentElement.SelectNodes("/configuration/appSettings/add[@value='1.0.0.0' and @key='webpages:Version']") | ForEach-Object { $_.ParentNode.RemoveChild($_); }

    # Changing root web.config compilation targetFramework version
    $rootConfig.DocumentElement."system.web".compilation.targetFramework = "4.5.2"

    # Removing old MVC related assembly binding information
    $deptAssemblies = $rootConfig.configuration.runtime.assemblyBinding.dependentAssembly
    Foreach ($deptAssembly in $deptAssemblies) {
        #Write-Host "Assembly Name " $deptAssembly.assemblyIdentity.name
        If($deptAssembly.assemblyIdentity.name -eq "System.Web.Helpers" -Or $deptAssembly.assemblyIdentity.name -eq "System.Web.Mvc" -Or $deptAssembly.assemblyIdentity.name -eq "System.Web.Webpages" -Or $deptAssembly.assemblyIdentity.name -eq "System.Web.Webpages.Deployment" -Or $deptAssembly.assemblyIdentity.name -eq "System.Web.Webpages.Razor")
        {
            $deptAssembly.ParentNode.RemoveChild($deptAssembly)
        }
    }

    [System.Xml.XmlNode] $assemblyBinding = $rootConfig.DocumentElement.SelectSingleNode("/configuration/runtime/rootConfig:assemblyBinding", $nameSpaceManager)

    # Adding System.Web.Helpers assembly binding information
    [System.Xml.XmlNode] $dependentAssembly = $rootConfig.CreateElement("dependentAssembly", $assemblyBindingNameSpace)
    [System.Xml.XmlNode] $assemblyIdentity = $rootConfig.CreateElement("assemblyIdentity", $assemblyBindingNameSpace)
    [System.Xml.XmlAttribute] $attribute = $rootConfig.CreateAttribute("name")
    $attribute.Value = "System.Web.Helpers";
    $assemblyIdentity.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("publicKeyToken")
    $attribute.Value = "31bf3856ad364e35";
    $assemblyIdentity.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($assemblyIdentity);
        
    [System.Xml.XmlNode] $bindingRedirect = $rootConfig.CreateElement("bindingRedirect", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("oldVersion")
    $attribute.Value = "1.0.0.0-2.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("newVersion")
    $attribute.Value = "3.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($bindingRedirect);
        
    $assemblyBinding.AppendChild($dependentAssembly);
        
    # Adding System.Web.Mvc assembly binding information
    $dependentAssembly = $rootConfig.CreateElement("dependentAssembly", $assemblyBindingNameSpace)
    $assemblyIdentity = $rootConfig.CreateElement("assemblyIdentity", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("name")
    $attribute.Value = "System.Web.Mvc";
    $assemblyIdentity.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("publicKeyToken")
    $attribute.Value = "31bf3856ad364e35";
    $assemblyIdentity.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($assemblyIdentity);
        
    $bindingRedirect = $rootConfig.CreateElement("bindingRedirect", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("oldVersion")
    $attribute.Value = "1.0.0.0-4.0.0.1";
    $bindingRedirect.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("newVersion")
    $attribute.Value = "5.2.3.0";
    $bindingRedirect.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($bindingRedirect);
        
    $assemblyBinding.AppendChild($dependentAssembly);

    # Adding System.Web.Webpages assembly binding information
    $dependentAssembly = $rootConfig.CreateElement("dependentAssembly", $assemblyBindingNameSpace)
    $assemblyIdentity = $rootConfig.CreateElement("assemblyIdentity", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("name")
    $attribute.Value = "System.Web.Webpages";
    $assemblyIdentity.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("publicKeyToken")
    $attribute.Value = "31bf3856ad364e35";
    $assemblyIdentity.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($assemblyIdentity);
        
    $bindingRedirect = $rootConfig.CreateElement("bindingRedirect", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("oldVersion")
    $attribute.Value = "1.0.0.0-2.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("newVersion")
    $attribute.Value = "3.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($bindingRedirect);
        
    $assemblyBinding.AppendChild($dependentAssembly);

    # Adding System.Web.Webpages.Deployment assembly binding information
    $dependentAssembly = $rootConfig.CreateElement("dependentAssembly", $assemblyBindingNameSpace)
    $assemblyIdentity = $rootConfig.CreateElement("assemblyIdentity", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("name")
    $attribute.Value = "System.Web.Webpages.Deployment";
    $assemblyIdentity.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("publicKeyToken")
    $attribute.Value = "31bf3856ad364e35";
    $assemblyIdentity.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($assemblyIdentity);
        
    $bindingRedirect = $rootConfig.CreateElement("bindingRedirect", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("oldVersion")
    $attribute.Value = "1.0.0.0-2.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("newVersion")
    $attribute.Value = "3.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($bindingRedirect);
        
    $assemblyBinding.AppendChild($dependentAssembly);

    # Adding System.Web.Webpages.Razor assembly binding information
    $dependentAssembly = $rootConfig.CreateElement("dependentAssembly", $assemblyBindingNameSpace)
    $assemblyIdentity = $rootConfig.CreateElement("assemblyIdentity", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("name")
    $attribute.Value = "System.Web.Webpages.Razor";
    $assemblyIdentity.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("publicKeyToken")
    $attribute.Value = "31bf3856ad364e35";
    $assemblyIdentity.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($assemblyIdentity);
        
    $bindingRedirect = $rootConfig.CreateElement("bindingRedirect", $assemblyBindingNameSpace)
    $attribute = $rootConfig.CreateAttribute("oldVersion")
    $attribute.Value = "1.0.0.0-2.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
        
    $attribute = $rootConfig.CreateAttribute("newVersion")
    $attribute.Value = "3.0.0.0";
    $bindingRedirect.Attributes.Append($attribute);
    $dependentAssembly.AppendChild($bindingRedirect);
        
    $assemblyBinding.AppendChild($dependentAssembly);

    $rootConfig.Save($rootConfigPath)

    # Change project type MVC 3 to MVC 5
    $configContent = [System.IO.File]::ReadAllText($project.FullName);
    $configContent = $configContent.Replace('E53F8FEA-EAE0-44A6-8774-FFD645390401', '349C5851-65DF-11DA-9384-00065B846F21');
    [System.IO.File]::WriteAllText($project.FullName, $configContent);
}
catch 
{
  Write-Host 'Exception' $($_.Exception.Message)
  throw
}