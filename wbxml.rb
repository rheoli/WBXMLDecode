#!/usr/bin/env ruby

#-Header=79

DEBUG=false

require 'airsync'

class Wbxml

  def initialize(_data)
    @tree={:header=>{}, :body=>[]}
    @data=nil
    if _data.class==File
      @data=_data.read_nonblock(5000)
    else
      @data=_data
    end
    @page={}
    @pos=nil
    @table=nil
    @output=""
  end

  def page(_page)
    print "=PAGE\n" if DEBUG
    print "  -> Search Page: #{_page}\n" if DEBUG
    airsync_table[_page]
  end

  def char2val(_type)
    val=0
    mult=1
    step=1
    step=2 if _type=="WORD"
    step=4 if _type=="DWORD"
    @pos.upto(@pos+step-1) do |i|
      val+=@data[i].ord*mult
      mult*=256
    end
    @pos+=step
    val
  end

  def string_table
    len=@data[@pos-1].ord
    return(@pos) if len==0
    @table=@data[@pos..(@pos+len-1)]
    print "  - Table = #{@table}\n" if DEBUG
    @pos+=1
  end

  def switch_page
    return if @data[@pos].ord!=0
    @pos+=1
    print " - Switch Page: #{@data[@pos]}\n" if DEBUG
    a=@data[@pos].ord
    @pos+=1
    [0, a]
  end

  def content(_space)
    print "=CONTENT" if DEBUG
    print "(#{@data[@pos].ord==3})\n" if DEBUG
    return(false) if @data[@pos].ord!=3
    s=""
    @pos+=1
    while(@data[@pos].ord!=0)
      s<<@data[@pos].ord
      @pos+=1
    end
    @pos+=1
    1.upto(_space) { @output<<" " }
    @output<<"#{s}\n"
    true
  end

  def tag(_space=0)
    return(false) if @data[@pos].ord==1
    print "=TAG" if DEBUG
    t_attr=(@data[@pos].ord&0x80)==0x80
    print "(ATTR)" if DEBUG and t_attr
    t_cont=(@data[@pos].ord&0x40)==0x40
    print "(CONTENT)" if DEBUG and t_cont
    print "\n" if DEBUG
    v=@data[@pos].ord
    v-=0x80 if t_attr
    v-=0x40 if t_cont
    @pos+=1
    t="#{@page[v]}"
    t="" if t.nil?
    t<<"(#{v})"
    e=""
    e="/" if !t_cont
    1.upto(_space) { @output<<" " }
    @output<<"<#{t}#{e}>\n"
    return(true) if !t_cont
    if !content(_space+1)
      while true
        switch_page
        break if !tag(_space+1)
      end
    end
    if @data[@pos].ord!=1
      raise "No endtag found."
    end
    @pos+=1
    1.upto(_space) { @output<<" " }
    @output<<"</#{t}>\n"
    true
  end

  def body(_space=0)
    print "=BODY\n" if DEBUG
    array=[]
    array+=switch_page
    array+tag(_space)
  end

  def parse
    print "=PARSE\n" if DEBUG
    return("") if @data.nil? or @data==""
    #Default page0 
    @page=page(0)
    @pos=0

    #-header
    char2val("BYTE")
    char2val("BYTE")
    char2val("BYTE")
    char2val("BYTE")
    
    body

  end
  
end

w=Wbxml.new(File.open("ibto_res_1289483569.wbxml"))
w.parse

