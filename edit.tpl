<html>
<head>
    <title>WSYIWYG Wiki Editor</title>
    <script type="text/javascript" src="js/jquery.min.js"></script> 
    <script type="text/javascript" src="js/creole.js"></script> 
    <script type="text/javascript" src="js/jquery.zclip.js"></script>
    <script type="text/javascript" src="js/jquery.htmlClean.js"></script>
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <style type="text/css">
        body, input, textarea, select {
          background-color: #111;
          color: #aaa;
        }

        a, a:hover, a:visited {
          color: #07a;
        }

        .container {
            float: left;
            width: 100%;
        }
        .head {
            margin-bottom: 12px;
        }
        .column1 {
            float: left;
            width: 47%;
            margin-right: 24px;
        }
        .column2 {
            float: left;
            width: 47%;
            height: 700px;
            overflow: auto;
        }
        #title, #wikitext {
            width: 100%;
            border: 2px solid grey;
            padding: 6px;
            margin-bottom: 4px;
        }
        #category {
            width: 80%;
            border: 2px solid grey;
            padding: 6px;
            margin-bottom: 4px;
            margin-left: 12px;
        }
        .block {
            border: 2px solid grey;
            padding: 6px;
            margin-bottom: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="head">
            <a id="sign" href="#" onclick="EGO.sign()">Sign in</a>
            <a href="http://www.wikicreole.org/wiki/CheatSheet">cheat sheet</a>
            <span id="status"></span>
        </div>
        <div class="column1">
            <form>
                <input type="text" id="title" value=""></input>
                <textarea id="wikitext" rows="40"></textarea>
                <div class="block">
                    <span>Category</span>
                    <input type="text" id="category" value=""></input>
                </div>
                <div class="block">
                    <input type="button" id="copy" value="Copy raw html"></input>
                    <input type="button" id="copy-with-window" value="Copy raw html in prompt" onClick="EGO.copyRawHtml()"></input>
                    <input type="button" id="save" value="Save" onClick="EGO.save(true)"></input>
                </div>
                <div id="blogger" class="block">
                    <span>Blogger</span>
                    <select id="blogger-select" onchange="EGO.changeSelectedBlog(this)">
                        <option value="">- CHOOSE A BLOG -</option>
                    </select>
                    <input type="button" id="submit" value="Submit" onClick="EGO.addNewPost()"></input>
                </div>
            </form> 
        </div>
        <div class="column2">
            <div id="demo"></div>
        </div>
    </div>
    <!-- Blogger API seems to need an image? -->
    <img src="images/pixelImg.jpg"/>
    <script type="text/javascript"><!--
// Load the AJAX Search API
google.load("search", "1");

// Load the Google data JavaScript client library
google.load("gdata", "2.x", {packages: ['blogger']});

// Set init() to be called after JavaScript libraries load
google.setOnLoadCallback(init);

// The namespace of this project.
var EGO = {
    AUTHENTICATION_URL: 'https://www.blogger.com/feeds',
    PERSONAL_BLOG_LIST_URL: 'https://www.blogger.com/feeds/default/blogs',
    SELECTED_BLOG_URL: null
};

function init() {
    EGO.service = new google.gdata.blogger.BloggerService('GoogleInc-BloggedUpon-1');
    EGO.service.getBlogFeed(EGO.PERSONAL_BLOG_LIST_URL,
                            EGO.getBlogFeedHandler, EGO.errorHandler);
    EGO.displayBloggerUI();
};

//-------------------------------------------------------------------------------
// Helper functions to access Blogger. Reference the official example codes:
// http://code.google.com/p/gdata-javascript-client/source/browse/trunk/samples/blogger/blogged_upon/blogged_upon.html
//-------------------------------------------------------------------------------
EGO.getBlogFeedHandler = function(blogFeedRoot) {
    var blogArr = blogFeedRoot.feed.getEntries();
    var blogSelect = $('#blogger-select');

    for (var i = 0; i < blogArr.length; i++) {
        var newOption = document.createElement('option');
        var blogTitle = blogArr[i].getTitle().getText();
        var blogLocation = blogArr[i].getEntryPostLink().getHref();

        newOption.value = blogLocation;
        newOption.innerHTML = blogTitle;
        blogSelect.append($(newOption));
    }
};

EGO.changeSelectedBlog = function(blogSelect) {
  if (blogSelect.value !== '') {
      EGO.SELECTED_BLOG_URL = blogSelect.value.replace('http:', 'https:');
  } else {
      EGO.SELECTED_BLOG_URL = null;
  }
};

EGO.sign = function() {
    if (google.accounts.user.checkLogin(EGO.AUTHENTICATION_URL)) {
        google.accounts.user.logout();
    } else {
        EGO.save(false);
        var token = google.accounts.user.login(EGO.AUTHENTICATION_URL);
    }
    EGO.displayBloggerUI();
};

EGO.displayBloggerUI = function() {
    if (google.accounts.user.checkLogin(EGO.AUTHENTICATION_URL)) {
        $('#sign').html('Sign out');
        $('#blogger').show();
    } else {
        $('#sign').html('Sign in');
        $('#blogger').hide();
    }
};

EGO.addNewPost = function() {
    if (EGO.SELECTED_BLOG_URL === null) {
        alert("Please select a blog first!");
        return;
    }
    // Automatically save it when publishing a new post.
    EGO.save(true);

    var newPostContent = $('#demo').html();
    var newEntry = new google.gdata.blogger.PostEntry();

    var title = google.gdata.atom.Text.create($('#title').val());
    var originalContent = $('#demo').html();
    // Patch github gists.
    // <tt>&lt;script src="https://gist.github.com/fcamel/5830507.js"&gt;&lt;/script&gt;</tt>
    // -> <script src="https://gist.github.com/fcamel/5830507.js"></script>
    var finalContent = originalContent.replace(/<tt>&lt;script src=/g, '<script src=').replace("&gt;&lt;/script&gt;</tt>", "></script>");
    console.log(finalContent);
    var content = google.gdata.atom.Text.create(finalContent, 'html');
    var categories = $.map($('#category').val().split(','), $.trim);
    newEntry.setTitle(title);
    newEntry.setContent(content);
    for (var i = 0; i < categories.length; i++) {
        newEntry.addCategory(new google.gdata.atom.Category({
            'scheme': 'http://www.blogger.com/atom/ns#',
            'term': categories[i]
        }));
    }
    EGO.service.insertEntry(EGO.SELECTED_BLOG_URL, newEntry,
                            EGO.insertEntryHandler, EGO.errorHandler);
};

EGO.insertEntryHandler = function(entryRoot) {
    $('#status').html('<b>Post submitted successfully! Click <a href="'
                      +  entryRoot.entry.getHtmlLink().getHref()
                      +  '">here</a> to view it.</b>');
};

EGO.errorHandler = function(e) {
    alert(e.cause.status + ": " + e.message);
};
//-------------------------------------------------------------------------------
// Other functions.
//-------------------------------------------------------------------------------
EGO.copyRawHtml = function() {
    window.prompt("Copy to clipboard: Ctrl+C, Enter", $.htmlClean($('#demo').html()));
};

EGO.save = function(async) {
    // Save the draft.
    var post = {
        title: $('#title').val(),
        content: $('#wikitext').val()
    };
    $.ajax({
        'url': '/save',
        'type': 'post',
        'data': {
            'post': JSON.stringify(post),
            'linkMapping': JSON.stringify(EGO.linkMapping)
        },
        'async': async
    });
};

EGO.oldContent = '';
EGO.autoSave = function() {
    var content = $('#wikitext').val();
    if (EGO.oldContent !== content) {
        EGO.oldContent = content;
        EGO.save(true);
    }
};

$(document).ready(function(){
    var input = document.getElementById('wikitext');
    var demo = document.getElementById('demo');
    var creole = new Parse.Simple.Creole({
        forIE: document.all,
        interwiki: {
            WikiCreole: 'http://www.wikicreole.org/wiki/',
            Wikipedia: 'http://en.wikipedia.org/wiki/'
        },
        linkFormat: ''
    });

    // Load the saved draft.
    var post = $.ajax({ 'url': '/post', dataType: 'json', async: false}).responseText;
    post = JSON.parse(post);
    $('#title').val(post.title);
    $('#wikitext').val(post.content);

    // Load memorized links.
    var linkMapping = $.ajax({ 'url': '/link', dataType: 'json', async: false}).responseText;
    EGO.linkMapping = JSON.parse(linkMapping);
 
    EGO.render = function() {
        demo.innerHTML = '';
        creole.parse(demo, input.value);

        /*
         * patch the result to fit my requirements.
         */
        // fit Blogger's plugin to add syntax color to the code snippets.
        $('#demo').find('pre').attr('class', 'prettyprint');

        // patch memorized links to the content.
        $('#demo a').filter(function(index) {
            return $(this).attr('href') === $(this).text();
        }).each(function(index, value) {
            var value = $(value);
            var text = value.text();
            var href = EGO.linkMapping[text];
            if (href !== undefined) {
                value.attr('href', href);
            }
        });

        // extend the link mapping.
        $('#demo a').filter(function(index) {
            return $(this).attr('href') !== $(this).text();
        }).each(function(index, value) {
            var value = $(value);
            var text = value.text();
            EGO.linkMapping[text] = value.attr('href');
        });
    };
 
    input.onkeyup = function() {
        EGO.render();
    };
 
    EGO.render();

    $('#copy').zclip({
        path:'swf/ZeroClipboard.swf',
        copy:function(){ return $('#demo').html(); }
    });


    // Auto save.
    window.setInterval(EGO.autoSave, 1000);
});
</script>
</body>
</html>
