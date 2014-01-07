
<#
.Synopsis
   Configure name resolution for IISExpress
.DESCRIPTION
   
.EXAMPLE
   "Yourwebsite" -DomainName "yourwebsite.com" -IP "192.168.1.2" -Port "1476"
    will bind  yourwebsite.com:1476 et 192.168.1.2:1476
#>
function Add-WebsiteBinding
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # SiteName Name of the website you want to configure, case sensitive
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $SiteName,

        # DomainName full domain name (without port) you want to use
        [string]
        [Parameter(Mandatory=$false
                   )]
        $DomainName,
        # IP direct IP access
        [string]
        [Parameter(Mandatory=$false)]
        $IP,
        # Port used port
        [int]
        [Parameter(Mandatory=$false)]
        $Port = 80
    )

    Begin
    {
      $confpath = $HOME+"\Documents\IISExpress\config\applicationhost.config" ;
      [xml]$CurrentConfig = Get-Content $confpath;
    }
    Process
    {
        
        
        
        
        $nodePath = "//site[@name= '"+$SiteName+"' ]/bindings/binding";
        
        $UrlNode = Select-Xml $nodePath $CurrentConfig;
        
        $copy = $UrlNode.Node[0].Clone();
        $copy2 = $UrlNode.Node[0].Clone();
        #create elements
        if($DomainName -ne "" ){
           $copy.bindingInformation ="*:"+$Port.ToString()+":"+$DomainName;
          $UrlNode.Node.ParentNode.AppendChild($copy);
          Write-Verbose "Added "+$DomainName+":"+$Port+" binding";
        }
        if($IP -ne ""){
            $copy2.bindingInformation = "*:"+$Port.ToString()+":"+$IP;
            $UrlNode.Node.ParentNode.AppendChild($copy2);
            Write-Verbose "Added "+$Ip+":"+$Port+" binding";
        }
        #formate
        $CurrentConfig.PreserveWhitespace = $true;
        Set-Content $confpath $CurrentConfig.InnerXml;
    }
    End
    {

    }
}
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-WebsiteBinding
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # SiteName Name of the website you want to configure, case sensitive
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,

                   Position=0)]
        [string]
        $SiteName,

        # DomainName full domain name (without port) you want to use
        [string]
        [Parameter(Mandatory=$true
                   )]
        $DomainName,
        # All true if you want to get all bindings out
        [switch]
        [Parameter(Mandatory=$false)]
        $All,
        # IP direct IP access
        [string]
        [Parameter(Mandatory=$false)]
        $IP,
        # Port used port
        [int]
        [Parameter(Mandatory=$false)]
        $Port = 80
    )

    Begin
    {
      $confpath = $HOME+"\Documents\IISExpress\config\applicationhost.config" ;
      [xml]$CurrentConfig = Get-Content $confpath;
    }
    Process
    {
      $nodePath = "//site[@name= '"+$SiteName+"' ]/bindings/binding";
      if($All){
        $AllNodes = Select-Xml $nodePath $CurrentConfig; 
        foreach ($node in $AllNodes.Node)
        {
            Write-Verbose "removed "+$node.bindingInformation;
            $node.ParentNode.RemoveChild($node);

        }
      }else{
        if($IP){
          $infos = "*:$IP`:$Port";
        }
        $nodePath += "[@bindingInformation='$infos']";
        $toRemove = Select-Xml $nodePath $CurrentConfig;
        $toRemove.Node[0].ParentNode.RemoveChild($toRemove.Node[0]);
        Write-Verbose "removed $infos";

        if($DomainName){
          $infos = "*:$IP`:$DomainName";
        }
        $nodePath += "[@bindingInformation='$infos']";
        $toRemove = Select-Xml $nodePath $CurrentConfig;
        $toRemove.Node[0].ParentNode.RemoveChild($toRemove.Node[0]);
        Write-Verbose "removed $infos";
      }
        
    }
    End
    {
    }
}
<#
.Synopsis
   Get the already existing websites
.DESCRIPTION
   Long description
.EXAMPLE
   Get-Website 
   gets the list of all website
.EXAMPLE
   Get-Website "Site"
   gets the list of all website whose name contains "Site"(case Insensitive)
.EXAMPLE
   Get-Website "Site" -Case
   gets the list of all website whose name contains "Site"(case sensitive)
.EXAMPLE 
   Get-Website "Site" -Exact
   gets the website that has "Site" as exact name (case insensitive)
#>
function Get-Website 
{
    [CmdletBinding()]
    [OutputType([object[]])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $SiteName,
        [Parameter(Mandatory=$false)]
        [Switch]$Case,
        [Parameter(Mandatory=$false)]
        [Switch]$Exact
    )

    Begin
    {
          $confpath = $HOME+"\Documents\IISExpress\config\applicationhost.config" ;
          [xml]$CurrentConfig = Get-Content $confpath;
    }
    Process
    {
        
        $nodePath ="//site";
        if(($Case -or $Exact)-and !$SiteName){
            Write-Error("Can't use those parameters if no site name is provided");
        }
        
        $UrlNode = Select-Xml $nodePath $CurrentConfig;
        [string[]]$result = @();
        foreach ($node in $UrlNode.Node)
        {
            
            if($SiteName){
                Write-Verbose $SiteName;
                Write-Verbose $node.name.ToString();
                if($Case){
                    $toCompare = $node.name.ToString();
                }else{
                    $toCompare = $node.name.ToString().ToLower();
                }
                if(!$Exact -and $toCompare.Contains($SiteName.ToLower())){

                    $result += @{'SiteName'=$node.name; 'Id'=$node.id };
                }elseif($Exact){
                    if($SiteName.CompareTo($toCompare) -eq 0){
                        $result += @{'SiteName'=$node.name; 'Id'=$node.id };
                    }
                }
            }elseif(!$SiteName){
                $result += @{'SiteName'=$node.name; 'Id'=$node.id };
            }

        }
        return $result; 
    }
    End
    {
    }
}
