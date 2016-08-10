<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SearchEngine.cs" Inherits="SearchEngine.SearchEngineSpider" %>
<%@ import Namespace="System.Text" %>
<%@ import Namespace="System.Text.RegularExpressions" %>
<%@ import Namespace="System" %>
<%@ import Namespace="System.Net" %>
<%@ import Namespace="SearchEngine" %>

<script runat="server">
    private string baseURL = @"https://www.cia.gov/library/publications/the-world-factbook";
    private Queue<string> toBeProcessed = new Queue<string>();
    private HashSet<string> visited = new HashSet<string>();
    private SearchContainer m_Container = new SearchContainer();
    int count = 0;
    WebClient client = new WebClient();
    UTF8Encoding encoding = new UTF8Encoding();

    public void PAGE_Load(object sender, EventArgs e)
    {
        toBeProcessed.Enqueue(baseURL);
        spider();

        Cache["SearchContainer"] = m_Container;
        Cache["Reload"] = 2;

        Response.Write ("\n\nAdded to Cache!");
        Response.Flush();

        if(m_Container.Length > 0)
        {
            Server.Transfer ("SearchEngine.aspx");
        }
    }

    private void spider()
    {
        while (toBeProcessed.Count > 0 && count < 200)
        {
            string myURL = toBeProcessed.Dequeue();
            if (myURL[myURL.Length - 1] != '/')
            {
                myURL = myURL + "/";
            }
            Regex.Replace(myURL, @"//", @"/");
            if (!visited.Contains(myURL))
            {
                processFile(myURL);
                visited.Add(myURL);
                count++;
            }
        }
    }

    private void processFile(string myURL)
    {
        try
        {
            string fileContents, fileTitle, fileDescription;
            long fileSize;
            string[] wordArray;
            Response.Write("Visited " + myURL);
            fileContents = encoding.GetString(client.DownloadData(myURL));

            //Split string into words and then parse into an array
            string strippedToJustWords = stripToJustWords(fileContents);
            wordArray = strippedToJustWords.Split(' ');
            //Get the title of the file
            Match TitleMatch = Regex.Match(fileContents, "<title>([^<]*)</title>", RegexOptions.IgnoreCase | RegexOptions.Multiline);
            fileTitle = TitleMatch.Groups[1].Value;
            //Get the description of the file
            fileDescription = getDescription(fileContents, strippedToJustWords);
            //Get length of file
            fileSize = fileContents.Length;

            //Create result and add it to catalog
            Result myResult = new Result(myURL, fileTitle, fileDescription, DateTime.Now, fileSize);
            int index = 0;
            foreach (string word in wordArray)
            {
                string key = word.Trim(' ', '?', '\"', ',', '\'', ';', ':', '.', '(', ')').ToLower();
                m_Container.AddWord(key, myResult, index);
                index++;
            }
            Response.Write(" handled " + index + " words<br />");
            Response.Flush();
            findLinks(fileContents,myURL);
        }
        catch
        {
            Response.Write("Failed to download " + myURL + "<br />");
        }
    }

    //TODO: Make this better
    //Find all the links on the page and add them to toBeProcessed
    private void findLinks(string fileContents, string baseURL)
    {
        foreach (Match match in Regex.Matches(fileContents
                , @"(?<=<(a|area)\s+href="").*?(?=""\s*/?>)"
                , RegexOptions.IgnoreCase|RegexOptions.ExplicitCapture)) {

            string link = match.Value;

            int spacePos = link.IndexOf(' ');
            int quotePos = link.IndexOf('"');

            int chopPos = (quotePos<spacePos?quotePos:spacePos);

            if (chopPos > 0) {
                link = link.Substring(0,chopPos);
            }

            if ( (link.Length > 8) && (link.Substring(0, 7).ToLower() == "http://") ) {
                //External link
                toBeProcessed.Enqueue(link);
            } else {
                //Internal link
                link = baseURL + link;
                toBeProcessed.Enqueue(link);
            }

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

</script>

<html>
    <body>
        <button onclick="spiderStart()"></button>
    </body>
</html>
