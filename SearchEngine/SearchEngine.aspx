<%@ Page Language="C#" autoeventwireup="true" CodeBehind="SearchEngine.cs" Inherits="SearchEngine.SearchEngine" %>
<%@ import Namespace="System" %>
<%@ import Namespace="System.Xml.Serialization" %>
<%@ import Namespace="System.Collections.Specialized" %>
<%@ import Namespace="SearchEngine" %>

<script runat="server">

    public int wordCount;
    private SearchContainer m_Container;

    public void PAGE_Load(Object sender,EventArgs e){
        try
        {
            //If there you've gone to server, reload
            int reload = (int)Cache["Reload"];
            if (reload == 2)
            {
                Response.Write("<Html>");
                Cache["Reload"] = 1;
            }
        }
        catch
        {

        }
        try
        {
            m_Container = (SearchContainer)Cache["SearchContainer"];
            wordCount = m_Container.Length;
        }
        catch(Exception ex)
        {
            m_Container = null;
            Response.Write("Catalog unavailable from cache: " + ex.ToString());
        }
        if(m_Container == null)
        {
            //Server.Transfer("SearchEngineCrawler.aspx");
            Server.Transfer("SearchEngineSpider.aspx");
        }
        Response.Write("<html>");
        if (IsPostBack && m_Container != null)
        {
            search(searchbox.Text);
        }
    }

    public void xxSearch_Click(Object sender, EventArgs e)
    {
        search(searchbox.Text);
    }

    private void search(string input)
    {
        string parsedInput = input.Trim(' ', '?','\"', ',', '\'', ';', ':', '.', '(', ')').ToLower();
        if(parsedInput == String.Empty)
        {
            Response.Write("<br />Invalid Input");
            Response.End();
        }
        else
        {
            Hashtable resultTable = m_Container.Search(parsedInput);
            if(resultTable == null)
            {
                Response.Write("No pages match that entry");
            }
            else
            {
                Response.Write("<Html>Found!<br>");
                SortedList results = new SortedList(resultTable.Count);
                DictionaryEntry entry;
                Result curResult;
                int numOfMentions;
                foreach(object o in resultTable)
                {
                    entry = (DictionaryEntry)o;
                    curResult = (Result)entry.Key;
                    numOfMentions = (int)entry.Value;
                    string result = formatLinks(curResult, numOfMentions);
                    int rank = -1 * numOfMentions;
                    if (results.Contains(rank))
                    {
                        results[rank] = ((string)results[rank]) + result;
                    }
                    else
                    {
                        results.Add(rank,result);
                    }
                }
                foreach(object s in results)
                {
                    Response.Write((string)((DictionaryEntry)s).Value);
                }
                Response.End();
            }
        }
    }

    public string formatLinks(Result page, int numOfMentions)
    {
        string result = "";
        result = ("<a href=" + page.url + ">");
        result += ("<b>" + page.title + "</b></a>");
        result += (" <a href=" + page.url + " target=\"_TOP\" ");
        result += ("title=\"open in new window\" style=\"font-size:xx-small\">&uarr;</a>");
        result += (" <font color=gray>("+numOfMentions+")</font>");
        result += ("<br>" + page.details + "..." ) ;
        result += ("<br><font color=green>" + page.url + " - " + page.fileSize);
        result += ("bytes</font> <font color=gray>- " + page.lastCrawled + "</font><p>" ) ;
        return result;
    }
</script>
<!DOCTYPE html>
<html>
  <head>
    <title>Daniel's Search Engine</title>

    <style type="text/css">
    body{margin:0px 0px 0px 0px;font-family:trebuchet ms, verdana, arial, sans-serif;background-color:white;}
    .heading{font-size:xx-large;font-weight:bold;color:darkgrey;filter:DropShadow (Color=#cccccc, OffX=5, OffY=5, Positive=true)}
    .copyright{font-size:xx-small;}
	</style>
</head>
    <body>
        <form runat="server" id="content">
            <center>
            <p class="heading"><font color="red">Daniel's Search Engine</font></p>

            <table cellspacing="0" cellpadding="4" frame="box" bordercolor="#dcdcdc" rules="none" style="BORDER-COLLAPSE: collapse">
                <tr>
                    <td>
                    <p class="intro">Search for this word (single words only)...<br>
                        <asp:textbox id="searchbox" runat="server" width="300" />
                        <asp:RequiredFieldValidator ControlToValidate="searchbox" runat="server">&larr;</asp:RequiredFieldValidator></p>
                    </td>
                </tr>
                <tr><td align="center"><asp:button runat="server" text="Search" class="button" /></td></tr>
            </table>
            </center>
        </form>
    </body>
</html>
