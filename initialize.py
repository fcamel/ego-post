#!/usr/bin/env python
# -*- encoding: utf8 -*-

import os
import sqlite3


__author__ = 'fcamel'


def _execute(conn, sql, verbose=True, commit=True):
    if verbose:
        print sql
    conn.execute(sql)
    if commit:
        conn.commit()

def _create_posts(conn):
    sql = 'CREATE TABLE posts (id integer primary key, title text, content text);'
    _execute(conn, sql)

def _create_links(conn):
    sql = 'CREATE TABLE links (id integer primary key, text text unique, href text);'
    _execute(conn, sql)

    pairs = [
        ('Google', 'http://www.google.com'),
        ('fcamel', 'http://fcamel-fc.blogspot.com'),
        ('料理鼠王', 'http://zh.wikipedia.org/wiki/%E6%96%99%E7%90%86%E9%BC%A0%E7%8E%8B'),
    ]
    for text, href in pairs:
        sql = "INSERT INTO links (text, href) VALUES ('%s', '%s');" % (text, href)
        _execute(conn, sql)

def main():
    '''\
    %prog [options]

    Create and insert sample rows to the database "data.db"
    '''
    DB_FILE_NAME = 'data.db'

    if os.path.exists(DB_FILE_NAME):
        print ('%s exists. Remove it manually if you insist to create it.'
               '' % DB_FILE_NAME)
        return 1

    conn = sqlite3.connect(DB_FILE_NAME)

    _create_posts(conn)
    _create_links(conn)

    print '\nSuccesfully create %s' % DB_FILE_NAME

    return 0


if __name__ == '__main__':
    main()
