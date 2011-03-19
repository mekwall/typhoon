fs = require 'fs'
path = require 'path'
markdown = require('node-markdown').Markdown
require './patches'

class Article

  @baseUrl: (value = '') ->
    if value
      @_baseUrl = value
      this
    else
      @_baseUrl || ''

  @fromFile: (file, encoding, callback) ->
    fs.readFile file, encoding, (err, data) ->
      return callback err if err
      article = new Article data
      if !article.meta 'date'
        date = path.basename(file).match(/^([0-9]{4}-[0-9]{2}-[0-9]{2})-/)[1].replace(/-/g, '/')
        article.meta 'date', date
      article.meta 'slug', path.basename(file, path.extname(file)).match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}-(.*)$/)[1]
      callback null, article

  constructor: (data) ->
    data = data.replace /\r\n/g, "\n"
    meta = data.split(/\n\n/, 1).toString()

    @body data.substring meta.length + 2

    while match = meta.match /([a-z0-9]+)\:\s*(.*)\s*\n?/i
      @meta match[1].toLowerCase(), match[2]
      meta = meta.substring match[0].length

  body: (body = null) ->
    if body
      @_body = body
      this
    else
      markdown @_body

  meta: (key = null, value = null) ->
    @_meta = {} if !@_meta

    if value
      @_meta[key] = value
      this
    else if key
      @_meta[key]
    else
      @_meta

  title: -> @meta 'title'

  date: (raw = false) ->
    date = @meta 'date'
    if raw
      return date
    else
      [year, month, day] = date.split '/'
      new Date Date.UTC year, month - 1, day

  slug: -> @meta('slug') || @title().slug()

  permalink: (relative = false) ->
    date = @date()

    base = if relative then '' else Article.baseUrl()

    base + '/' + [
      date.getUTCFullYear(),
      (date.getUTCMonth() + 1).pad()
      date.getUTCDate().pad(),
      @slug()
    ].join '/'

###
Module Exports
###

exports.Article = Article
