[xml]$myXML = Get-Content "C:\Users\shiro\Desktop\test.xml"
$testlist = $myXML.testlist
foreach($node in $testlist.node)
{
    foreach($content in $node.content)
    {
        if($content.name -eq "password")
        {
            $content.InnerText = "bazzword"
        }
    }
}
$myXML.Save("C:\Users\shiro\Desktop\test2.xml")