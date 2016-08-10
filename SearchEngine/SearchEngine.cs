using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace SearchEngine
{
    public class SearchContainer
    {
        public SearchContainer()
        {
            wordIndex = new Hashtable();
        }

        private Hashtable wordIndex;

        public int Length
        {
            get { return wordIndex.Count; }
        }

        public bool AddWord(string myWord, Result myResult, int myPosition)
        {
            Word newWord;
            if (wordIndex.Contains(myWord))
            {
                newWord = (Word)wordIndex[myWord];
                newWord.AddResult(myResult, myPosition);
                return true;
            }
            else
            {
                newWord = new Word(myWord, myResult, myPosition);
                wordIndex.Add(myWord, newWord);
                return false;
            }
        }

        public Hashtable Search(string searchWord)
        {
            searchWord = searchWord.Trim(' ', '?', '\"', ',', '\'', ';', ':', '.', '(', ')').ToLower();
            if (wordIndex.ContainsKey(searchWord))
            {
                return ((Word)wordIndex[searchWord]).WordInResults();
            }
            else return null;
        }
    }
    public class Word
    {
        public string value;
        private Hashtable results;
        public Word(string myValue, Result myResult, int myPosition)
        {
            value = myValue;
            results = new Hashtable();
            results.Add(myResult, 1);
        }
        public void AddResult(Result myResult, int myPosition)
        {
            if (results.Contains(myResult))
            {
                int old = (int)results[myResult];
                results[myResult] = old + 1;
            }
            else
            {
                results.Add(myResult, 1);
            }
        }
        public Hashtable WordInResults()
        {
            return results;
        }
    }
    public class Result
    {
        public Result(string myUrl, string myTitle, string myDetails, DateTime myLastCrawled, long myFileSize)
        {
            url = myUrl;
            title = myTitle;
            details = myDetails;
            lastCrawled = myLastCrawled;
            fileSize = myFileSize;
        }
        public string url;
        public string title;
        public string details;
        public DateTime lastCrawled;
        public long fileSize;
    }
}