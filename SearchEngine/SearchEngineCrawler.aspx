<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SearchEngine.cs" Inherits="SearchEngine.SearchEngineCrawler" %>
<%@ import Namespace="System" %>
<%@ import Namespace="System.Xml.Serialization" %>
<%@ import Namespace="System.Collections.Specialized" %>
<%@ import Namespace="SearchEngine" %>
<script runat="server">
    //Replace with root directory and root 
    private string m_path = @"C:\Users\Danny\Downloads\factbook\factbook";
    private string m_url = @"https://www.cia.gov/library/publications/the-world-factbook";
    private string m_filter = "*.html";

    /// <summary>Working variable for the catalog being built</summary>
    private SearchContainer m_Container;

    public void crawl(string root, string path) {
        string fileUrl, fileContents,fileTitle,fileDescription;
        long fileSize;
        string[] wordArray;
        Response.Flush();
        System.IO.DirectoryInfo m_dir = new System.IO.DirectoryInfo (path);
        // Look for matching files to summarise what will be catalogued
        foreach (System.IO.FileInfo f in m_dir.GetFiles(m_filter)) {
            //Write the parsed file to the output
            Response.Write (path.Substring(root.Length) + @"\" + f.Name);
            Response.Flush();

            //Get the url of the file and open it
            fileUrl = m_url + path.Substring(root.Length).Replace(@"\","/") + "/" + f.Name;
            System.IO.StreamReader r = System.IO.File.OpenText(path + @"\" + f.Name);
            fileContents = r.ReadToEnd();
            r.Close();

            //Split string into words and then parse into an array
            string strippedToJustWords = stripToJustWords(fileContents);
            wordArray = strippedToJustWords.Split(' ');
            //Get the title of the file
            Match TitleMatch = Regex.Match(fileContents, "<title>([^<]*)</title>", RegexOptions.IgnoreCase | RegexOptions.Multiline );
            fileTitle = TitleMatch.Groups[1].Value;
            //Get the description of the file
            fileDescription = getDescription(fileContents, strippedToJustWords);
            //Get length of file
            fileSize = fileContents.Length;

            //Create result and add it to catalog
            Result myResult = new Result(fileUrl, fileTitle, fileDescription, DateTime.Now, fileSize);
            int index = 0;
            foreach(string word in wordArray)
            {
                string key = word.Trim(' ', '?','\"', ',', '\'', ';', ':', '.', '(', ')').ToLower();
                m_Container.AddWord(key, myResult, index);
                index++;
            }

            Response.Write(" handled " + index + " words<br />");
            Response.Flush();

        }
        foreach (System.IO.DirectoryInfo d in m_dir.GetDirectories()) {
            crawl(root, path + @"\" + d.Name);
        }
    }

    //Gets the description of a file given its contents. If no description, takes first part of file
    private string getDescription(string fileContents, string parsedContents)
    {
        Match DescriptionMatch = Regex.Match( fileContents, "<META NAME=\"DESCRIPTION\" CONTENT=\"([^<]*)\">",
                                              RegexOptions.IgnoreCase | RegexOptions.Multiline );
        string description = DescriptionMatch.Groups[1].Value;
        if(description == null || description == String.Empty)
        {
            if(parsedContents.Length > 200)
            {
                description = parsedContents.Substring(0, 200);
            }
            else
            {
                description = parsedContents;
            }
        }
        return description;
    }

    //Takes in the file as a string, removes html and parses remaining raw text into space seperated words
    private string stripToJustWords(string rawString)
    {
        //Strip html
        string strippedString = removeHTML(rawString);

        //Parse out excess whitespace
        Regex r = new Regex(@"\s+");
        return r.Replace(strippedString, " ");
    }

    //Takes all of the html tags out leaving raw text
    private string removeHTML(string original)
    {
        //Strips the HTML tags from strHTML
        System.Text.RegularExpressions.Regex objRegExp = new System.Text.RegularExpressions.Regex("<(.|\n)+?>");

        // Replace all tags with a space,
        string strOutput = objRegExp.Replace(original, " ");

        // Replace all < and > with &lt; and &gt;
        strOutput = strOutput.Replace("<", "&lt;");
        strOutput = strOutput.Replace(">", "&gt;");

        return strOutput;
    }

    public void PAGE_Load(object sender, EventArgs e)
    {
        m_Container = new SearchContainer();
        Response.Write(@"<html>
             <head>
             <title>Crawling files</title>
             </head>
             <body>
             <h3>Daniel's Search Engine</h3>
             Generating the catalog:<p>");
        crawl(m_path, m_path);

        Cache["SearchContainer"] = m_Container;
        Cache["Reload"] = 2;

        Response.Write ("\n\nAdded to Cache!");
        Response.Flush();

        if(m_Container.Length > 0)
        {
            Server.Transfer ("SearchEngine.aspx");
        }
        Response.End();
    }
</script>

<html>
    <body>
        <button onclick="crawlStart()"></button>
    </body>
</html>