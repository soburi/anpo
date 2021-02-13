# frozen_string_literal: true

require_relative "anpo/version"

module Anpo
  class Error < StandardError; end

  class POEntry
    attr_accessor :msgid
    attr_accessor :msgstr
    attr_accessor :comments
    attr_accessor :is_header

    def initialize(lines, header=false)
      state = ''
      @is_header = header
      @msgid = nil
      @msgstr = nil
      @comments = []
      lines.each do |l|
        if l.start_with?("msgid")
          state = "msgid"
          @msgid = l.gsub("msgid \"","").gsub(/\"\s*$/,"")
        elsif l.start_with?("msgstr")
          state = "msgstr"
          @msgstr = l.gsub("msgstr \"","").gsub(/\"\s*$/,"")
        elsif l.start_with?("#")
          state = "comment"
          @comments.push(l.gsub("\n",'') )
        else
          if state == "msgid"
            @msgid = @msgid + "\n" + l.gsub(/^\s*\"/,'').gsub(/\"\s*$/,'')
          elsif state == "msgstr"
            @msgstr = @msgstr + "\n" + l.gsub(/^\s*\"/,'').gsub(/\"\s*$/,'')
          end
        end
      end
    end

    def is_fuzzy?
      comments.grep(/#,.*fuzzy/).length != 0
    end

    def is_translated?
      @msgstr.empty? and not @msgid.empty?
    end

    def msgid_to_s
      if @msgid == nil and @is_header
        "msgid \"\"\n"
      elsif @msgid == nil
        ""
      else
        "msgid " + @msgid.split("\n").collect{|x| "\"#{x}\""}.join("\n") + "\n"
      end
    end

    def msgstr_to_s
      if @msgid == nil and not @is_header
        ""
      elsif @msgstr.empty?
        "msgstr \"\"\n"
      else
        "msgstr " + @msgstr.split("\n").collect{|x| "\"#{x}\""}.join("\n") + "\n"
      end
    end

    def comments_to_s
      if @comments.empty?
        ""
      else
        @comments.join("\n") + "\n"
      end
    end

    def to_s
      comments_to_s + msgid_to_s + msgstr_to_s 
    end
  end

  class PO

    include Enumerable

    def self.parse(file, &block)
      pofile = PO.new(file)
      if block
        block.call(pofile)
      else
        pofile
      end
    end

    attr_accessor :entries

    def [](key)
      @hcache[key]
    end

    def update_hashcache
      @hcache = {}
      @entries.each do |e|
        @hcache[e.msgid] = e.msgstr
      end
    end

    def entry(id)
      @entries.find {|e| e.msgid == id}
    end

    def each(&block)
      @entries.each do |e|
        block.call(e)
      end
    end

    def keys()
      @hcache.keys
    end

    def values()
      @hcache.values
    end

    def filter_by_ids(ids)
      filterids = @entries.collect {|e| e.msgid}

      if not (ids - filterids).empty?
        raise
      end

      filterids = filterids - ids
      @entries.delete_if {|e| filterids.include?(e.msgid)}
      update_hashcache
    end

    def delete_by_ids(deleteids)
      ids = @entries.collect {|e| e.msgid}

      if not (deleteids - ids).empty?
        raise
      end

      @entries.delete_if {|e| deleteids.include?(e.msgid)}
      update_hashcache
    end

    def initialize(file)
      @caches = []
      @entries = []
      @header = nil

      buffer = []

      while l = file.gets
        if not @header
          if l == "\n"
            @header = POEntry.new(buffer, true)
            buffer = []
          else
            buffer.push(l)
          end
          next
        end

        if l == "\n"
          ent = POEntry.new(buffer)
          if ent.msgid == nil
            @caches.push(ent)
          else
            if ent.msgid != nil and ent.msgid.empty?
              STDERR.print("duplicate header\n" + ent.to_s)
            else
              @entries.push(ent)
            end
          end
          buffer = []
        else
          buffer.push(l)
        end
      end
      ent = POEntry.new(buffer)
      if ent.msgid == nil
        @caches.push(ent)
      else
        if not (ent.msgid != nil and ent.msgid.empty?)
          @entries.push(ent)
        end
      end
      update_hashcache
      self
    end

    def to_s(with_cache=true)
      ([@header] + @entries + (with_cache ? @caches : [])).collect{|e| e.to_s}.join("\n").to_s
    end

  end
end
