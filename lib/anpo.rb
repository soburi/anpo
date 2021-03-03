# frozen_string_literal: true

require_relative "anpo/version"
require "csv"
require "stringio"

module Anpo
  class Error < StandardError; end

  class POEntry
    attr_accessor :comments

    def on_changed(&proc)
      @change_listener.push(proc)
    end

    def msgid
      @msgid.clone
    end

    def msgid=(id)
      @change_listener.each do |prc|
        prc.call(self, id, @msgstr)
      end
      @msgid = id
    end

    def msgstr
      @msgstr.clone
    end

    def msgstr=(str)
      @change_listener.each do |prc|
        prc.call(self, @msgid, str)
      end
      @msgstr = str
    end

    def initialize(lines = nil)
      state = ""
      @change_listener = []
      @msgid = nil
      @msgstr = nil
      @comments = []

      unless lines.nil?
        lines.each do |l|
          if l.start_with?("msgid")
            state = "msgid"
            @msgid = l.gsub("msgid \"", "").gsub(/"\s*$/, "")
          elsif l.start_with?("msgstr")
            state = "msgstr"
            @msgstr = l.gsub("msgstr \"", "").gsub(/"\s*$/, "")
          elsif l.start_with?("#")
            state = "comment"
            @comments.push(l.gsub("\n", ""))
          elsif state == "msgid"
            @msgid = @msgid + "\n" + l.gsub(/^\s*"/, "").gsub(/"\s*$/, "")
          elsif state == "msgstr"
            @msgstr = @msgstr + "\n" + l.gsub(/^\s*"/, "").gsub(/"\s*$/, "")
          end
        end
      end
    end

    def is_fuzzy?
      comments.grep(/#,.*fuzzy/).length != 0
    end

    def is_translated?
      (@msgid and !@msgid.empty?) and (@msgstr and !@msgstr.empty?)
    end

    def is_header?
      @msgid and @msgid.empty? and !@msgstr.empty?
    end

    def msgid_to_s
      if @msgid.nil?
        ""
      elsif is_header?
        "msgid \"\"\n"
      else
        "msgid " + @msgid.split("\n").collect { |x| "\"#{x}\"" }.join("\n") + "\n"
      end
    end

    def msgstr_to_s
      if @msgid.nil?
        ""
      elsif @msgstr.empty?
        "msgstr \"\"\n"
      else
        "msgstr " + @msgstr.split("\n").collect { |x| "\"#{x}\"" }.join("\n") + "\n"
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

  class PO < Array
    private

    def set_on_changed(entry)
      entry.on_changed do |_e, _newid, _newstr|
        @dirty = true
      end
    end

    public

    def <<(*args)
      super
      @dirty = true
    end

    def append(*args)
      super
      @dirty = true
    end

    def clear(*args)
      super
      @dirty = true
    end

    def collect!(*args)
      super
      @dirty = true
    end

    def compact!(*args)
      super
      @dirty = true
    end

    def concat(*args)
      super
      @dirty = true
    end

    def delete(*args)
      super
      @dirty = true
    end

    def delete_at(*args)
      super
      @dirty = true
    end

    def delete_if(*args)
      super
      @dirty = true
    end

    def fill(*args)
      super
      @dirty = true
    end

    def filter!(*args)
      super
      @dirty = true
    end

    def flatten!(*args)
      super
      @dirty = true
    end

    def insert(*args)
      super
      @dirty = true
    end

    def keep_if(*args)
      super
      @dirty = true
    end

    def map!(*args)
      super
      @dirty = true
    end

    def pop(*args)
      super
      @dirty = true
    end

    def prepend(*args)
      super
      @dirty = true
    end

    def push(*args)
      super
      @dirty = true
    end

    def reject!(*args)
      super
      @dirty = true
    end

    def replace(*args)
      super
      @dirty = true
    end

    def reverse!(*args)
      super
      @dirty = true
    end

    def rotate!(*args)
      super
      @dirty = true
    end

    def select!(*args)
      super
      @dirty = true
    end

    def shift(*args)
      super
      @dirty = true
    end

    def shuffle!(*args)
      super
      @dirty = true
    end

    def slice!(*args)
      super
      @dirty = true
    end

    def sort!(*args)
      super
      @dirty = true
    end

    def sort_by!(*args)
      super
      @dirty = true
    end

    def uniq!(*args)
      super
      @dirty = true
    end

    def unshift(*args)
      super
      @dirty = true
    end

    def msg
      if @dirty
        @msg.clear
        each do |e|
          @msg[e.msgid] = e.msgstr
        end
        @dirty = false
      end
      @msg
    end

    def self.parse(input, mode = "r", _opt = {}, &block)
      po = nil
      if input.is_a?(IO)
        po = PO.new(input)
      elsif FileTest.exists?(input.to_s)
        File.open(input.to_s, mode) do |f|
          po = PO.new(f)
        end
      end

      if block
        block.call(po)
        nil
      else
        po
      end
    end

    def entry(id)
      find { |e| e.msgid == id }
    end

    def new_entry(msgid, msgstr, comments = nil)
      poe = POEntry.new
      set_on_changed(poe)
      poe.msgid = msgid
      poe.msgstr = msgstr
      poe.comments = comments || []
      push(poe)
    end

    def filter_by_ids(keepids, _force = false)
      ids = collect { |e| e.msgid }

      raise unless (keepids - ids).empty?

      keep_if { |e| keepids.include?(e.msgid) }
    end

    def delete_by_ids(deleteids)
      ids = collect { |e| e.msgid }

      raise unless (deleteids - ids).empty?

      delete_if { |e| deleteids.include?(e.msgid) }
    end

    def initialize(io = nil)
      super()
      @caches = []
      @header = nil
      @msg = {}

      if io
        _self = self
        proc_new_entry = proc do |buf|
          ent = POEntry.new(buf)
          set_on_changed(ent)

          if ent.is_header?
            if @header
              STDERR.print("duplicate header\n" + ent.to_s)
            else
              @header = ent
            end
          elsif ent.msgid.nil?
            @caches.push(ent)
          else
            push(ent)
          end
        end

        buffer = []
        while (l = io.gets)
          if l == "\n"
            proc_new_entry.call(buffer)
            buffer = []
          else
            buffer.push(l)
          end
        end

        proc_new_entry.call(buffer)
      else
        @header = POEntry.new
        set_on_changed(@header)
        @header.msgid = ""
        @header.msgstr = "\n"
      end
    end

    def to_s(with_cache = true)
      ([@header] + self + (with_cache ? @caches : [])).collect { |e| e.to_s }.join("\n").to_s
    end

    def to_csv(opts = {})
      # CSV.new(StringIO.new, opts)
      csvstr = CSV.generate(opts) do |csv|
        ([@header] + self + @caches).each do |e|
          csv << [e.comments_to_s.chop, e.msgid, e.msgstr]
        end
      end
      CSV.new(StringIO.new(csvstr))
    end
  end
end
