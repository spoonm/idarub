#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))

require 'idarub'
require 'idarutils'

@ida, @sess = IdaRub.auto_client

irb
