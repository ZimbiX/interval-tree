#!/usr/bin/env ruby
#
# Title:: the IntervalTree module using "augmented tree"
# Author::   Hiroyuki Mishima, Simeon Simeonov, Carlos Alonso, Sam Davies
# Copyright:: The MIT/X11 license
#
# see also ....
#  description in Wikipedia
#    http://en.wikipedia.org/wiki/Interval_tree
#  implementation in Python by Tyler Kahn
#    http://forrst.com/posts/Interval_Tree_implementation_in_python-e0K
#
# Usage:
#  require "interval_tree"
#  itv = [(0...3), (1...4), (3...5),]
#  t = IntervalTree::Tree.new(itv)
#  p t.search(2) => [0...3, 1...4]
#  p t.search(1...3) => [0...3, 1...4, 3...5]
#
# note: result intervals are always returned
# in the "left-closed and right-open" style that can be expressed
# by three-dotted Range object literals (first...last)

module IntervalTree

  class Tree
    def initialize(ranges, &range_factory)
      range_factory = lambda { |l, r| (l ... r+1) } unless block_given?
      ranges_excl = ensure_exclusive_end([ranges].flatten, range_factory)
      @top_node = divide_intervals(ranges_excl)
    end
    attr_reader :top_node

    def divide_intervals(intervals)
      return nil if intervals.empty?
      x_center = center(intervals)
      s_center = Array.new
      s_left = Array.new
      s_right = Array.new

      intervals.each do |k|
        case
        when k.last < x_center
          s_left << k
        when k.first > x_center
          s_right << k
        else
          s_center << k
        end
      end
      Node.new(x_center, s_center,
               divide_intervals(s_left), divide_intervals(s_right))
    end

    DEFAULT_OPTIONS = {unique: true}
    def search(interval, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      return nil unless @top_node
      if interval.respond_to?(:first)
        first = interval.first
        last = interval.last
      else
        first = interval
        last = nil
      end

      if last
        result = Array.new
        (first...last).each do |j|
          search(j).each{|k|result << k}
          options[:unique] ? result.uniq! : result
        end
        result.sort_by{|x|[x.first, x.last]}
      else
        point_search(self.top_node, first, [], options[:unique]).sort_by{|x|[x.first, x.last]}
      end
    end

    private

    def ensure_exclusive_end(ranges, range_factory)
      ranges.map do |range|
        case
        when !range.respond_to?(:exclude_end?)
          range
        when range.exclude_end?
          range
        else
          range_factory.call(range.first, range.end)
        end
      end
    end

    # augmented tree
    # using a start point as resresentative value of the node
    def center(intervals)
      i = intervals.reduce([intervals.first.first, intervals.first.last]) { |acc, int| [[acc.first, int.first].min, [acc.last, int.last].max] }
      i.first + (i.last - i.first) / 2
    end

    def point_search(node, point, result, unique = true)
      node.s_center.each do |k|
        if k.include?(point)
          result << k
        end
      end
      if node.left_node && ( point < node.x_center )
        point_search(node.left_node, point, []).each{|k|result << k}
      end
      if node.right_node && ( point >= node.x_center )
        point_search(node.right_node, point, []).each{|k|result << k}
      end
      if unique
        result.uniq
      else
        result
      end
    end
  end # class Tree

  class Node
    def initialize(x_center, s_center, left_node, right_node)
      @x_center = x_center
      @s_center = s_center
      @left_node = left_node
      @right_node = right_node
    end
    attr_reader :x_center, :s_center, :left_node, :right_node
  end # class Node

end # module IntervalTree

if  __FILE__ == $0
  puts "This is the Augmented Interval Tree library."
end
