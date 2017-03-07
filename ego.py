#!/usr/bin/env python

import simplejson
import sqlite3
import os

import settings
import bottle
import bottle.ext.sqlite


__author__ = 'fcamel'


#-------------------------------------------------------------------------------
# Helper functions
#-------------------------------------------------------------------------------
def _get_link_mapping(db):
    cursor = db.execute('select text, href from links')
    links = {}
    for text, href in cursor.fetchall():
        links[text] = href
    return links

def _escape(string):
    return string.replace("'", "''").replace('\\', '\\\\')

#-------------------------------------------------------------------------------
# Serve static files.
#-------------------------------------------------------------------------------
@bottle.route('/images/:filename#.*#')
def send_js(filename):
    return bottle.static_file(filename,
                              root=os.path.join(settings.CODE_ROOT, 'images'),
                              mimetype='image/jpeg')

@bottle.route('/js/:filename#.*\.js#')
def send_js(filename):
    return bottle.static_file(filename,
                              root=os.path.join(settings.CODE_ROOT, 'js'),
                              mimetype='text/javascript')

@bottle.route('/swf/:filename#.*\.swf#')
def send_swf(filename):
    return bottle.static_file(filename,
                              root=os.path.join(settings.CODE_ROOT, 'swf'),
                              mimetype='application/x-shockwave-flash')

#-------------------------------------------------------------------------------
# Error handlers.
#-------------------------------------------------------------------------------
@bottle.error(403)
def mistake403(code):
    return 'There is a mistake in your url!'

@bottle.error(404)
def mistake404(code):
    return 'Sorry, this page does not exist!'

#-------------------------------------------------------------------------------
# Routes
#-------------------------------------------------------------------------------
@bottle.route('/new')
def edit():
    output = bottle.template('edit')
    return output

@bottle.route('/link')
def link(db):
    return _get_link_mapping(db)

@bottle.route('/post')
def post(db):
    cursor = db.execute('select title, content from posts where id = -1')
    row = cursor.fetchone()
    if row:
        title, content = row
    else:
        title = 'Demo'
        content = '\n'.join([
            "= Demo",
            "Here are my blogs:",
            " * [[http://fcamel-fc.blogspot.com/|fcamel's blog]]",
            " * [[http://fcamel-life.blogspot.com/|fcamel's technique notes]]",
        ])
    return { 'title': title, 'content': content }

# Update the draft.
@bottle.route('/save', method='POST')
def save(db):
    def _save_post(raw_post):
        if not raw_post :
            return { 'status': 'no data' }

        post = simplejson.loads(raw_post)
        title = _escape(post['title'])
        content = _escape(post['content'])

        sql = ("INSERT OR REPLACE INTO posts (id, title, content) "
               "VALUES (-1, '%s', '%s');" % (title, content))
        db.execute(sql)

        return { 'status': 'updated' }

    def _save_link_mapping(raw_link_mapping):
        if not raw_link_mapping :
            return { 'status': 'no data', 'updated': 0 }

        link_mapping = _get_link_mapping(db)
        new_link_mapping = simplejson.loads(raw_link_mapping)

        update_count = 0
        for text, href in new_link_mapping.items():
            if text not in link_mapping or href != link_mapping[text]:
                sql = ("INSERT OR REPLACE INTO links (text, href) "
                       "VALUES ('%s', '%s');" % (_escape(text), _escape(href)))
                db.execute(sql)
                update_count += 1

        return { 'status': 'updated', 'updated': update_count }

    return {
        'draft': _save_post(bottle.request.POST.get('post', '')),
        'linkMapping': \
            _save_link_mapping(bottle.request.POST.get('linkMapping', '')),
    }


bottle.debug(True)
app = bottle.app()
plugin = bottle.ext.sqlite.Plugin(dbfile='data.db')
app.install(plugin)

bottle.run(reloader=True, port=8001, host='0.0.0.0')
