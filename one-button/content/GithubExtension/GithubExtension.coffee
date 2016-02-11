#include https://github.com/*
#require jquery.min

((GithubExtension) ->

  GithubExtension.router =
    url: /^https:..github.com(.*)commits(.*)$/
    onClick: (isFirstTime) ->
      unless isFirstTime then return
      requireAll require.context('./css', true, /\.(less|css)$/)
      git_commits_box  = require('./html/commits_box.handlebars')

      $('body').css('margin-top', '120px').prepend git_commits_box()

      class Commits
        @commits = {}
        @authors = {}

        @put: (day, author, commit) ->
          commits = Commits.commits
          day = commits[day] ?= {}
          commitsOfAuthor = day[author] ?= []
          hasCommit = false
          for commitOfAuthor in commitsOfAuthor
            if commit is commitOfAuthor
              hasCommit = true
              break
          unless hasCommit
            commitsOfAuthor.push commit
            Commits.authors[author] ?= 0
            Commits.authors[author] += 1

        @print: ->
          days = for day, value of Commits.commits
            day
          days.sort()
          result = ''
          for day in days
            result += day.split('-').reverse().join('.') + '\n'
            authors = Commits.commits[day]
            count = 0
            for author, c of Commits.authors
              count++
            if count > 1
              for author, comits of authors
                result += '\n' + author + ':\n' + comits.join('. ') + '.'
            else
              for author, comits of authors
                result += '\n' + comits.join('. ') + '.'
            result += '\n\n'
          return result

        @drawAuthors: ->
          $stat = $('#stat0304').empty()
          for author, count of Commits.authors
            $stat.append '<tr><td style="letter-spacing: 1px; font-weight: 300;"> ' + author + ' </td><td style="text-align: center;"> – </td><td style="font-weight: 300;"> ' + count + ' </td></tr>'

        @drawPrint: ->
          $("#commits0304").val Commits.print()
          $('#commits0304').focus().select()
          document.execCommand('copy');

        @clear: ->
          Commits.commits = {}
          Commits.authors = {}
          $("#commits0304").val('')
          $('#stat0304').empty()

      $('#clear0304').on 'click', -> Commits.clear()
      $('#print0304').on 'click', -> Commits.drawPrint()

      class Day
        @monthsNames = "Jan_Feb_Mar_Apr_May_Jun_Jul_Aug_Sep_Oct_Nov_Dec".split('_')
        @monthsNumbers = "01_02_03_04_05_06_07_08_09_10_11_12".split('_')

        monthNumber: (mmm) ->
          unless Day.month
            Day.month = {}
            for i in [0...12] by 1
              Day.month[Day.monthsNames[i]] = Day.monthsNumbers[i]
          return Day.month[mmm]

        constructor: (title) ->
          titleParts = title.replace(',','').split(' ').reverse()
          day = titleParts[1]
          if day and day.length < 2 then day = '0' + day
          @title = titleParts[0] + '-' + @monthNumber(titleParts[2]) + '-' + day

        addCommit: (author, text) ->
          if text
            lines = text.split('\n')
            result = ''
            if lines and lines.length > 0
              for line in lines
                if line and line.length > 0
                  if line.indexOf('Merge branch') < 0 and line.indexOf('Conflicts:') < 0
                    result += line
                  else
                    break
              if result and result.length > 0
                Commits.put @title, author, result.replace(/\.\s*$/, "").replace('  ','')

      $('#parse0304').on 'click', ->
        result = []
        day = null
        $(".commits-listing").children().each (i, el) ->
          $el = $(el)
          if el.tagName is 'DIV'
            $el.find(".octicon").remove()
            result.push day = new Day($el.text().trim())
          else
            if el.tagName is 'OL'
              $el.children().each (i, el) ->
                $com = $(el)
                text = $com.find('.commit-title .message').first().attr('title').trim()
                author = $com.find('.commit-author').first().text()
                day.addCommit author, text

        Commits.drawAuthors()

)(OButton.GithubExtension ?= {})
