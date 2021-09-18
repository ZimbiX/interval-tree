require 'spec_helper'

describe "IntervalTree::Node" do
  describe '.new' do
    context 'given ([], [], [], [])' do
      it 'returns a Node object' do
        expect(IntervalTree::Node.new([], [], [], [])).to be_a(IntervalTree::Node)
      end
    end
  end

  describe '#search' do
    subject(:result) { node.search(-5...3) }

    let(:node) do
      IntervalTree::Tree.new(
        [
          10...14,
          2...20,
          0...5,
          0...8,
          3...6,
          15...20,
          16...21,
          17...25,
          21...24,
        ],
      ).top_node
    end

    before do
      allow(node.left_node).to receive(:search).and_call_original
      allow(node.right_node).to receive(:search).and_call_original
      result
    end

    it 'returns the matching ranges' do
      expect(result).to eq(
        [
          2...20,
          0...5,
          0...8,
        ]
      )
    end

    context 'only searches the necessary nodes' do
      it 'searches the left node' do
        expect(node.left_node).to have_received(:search)
      end

      it "does not search the right node, since the top node's center (12) is greater than the search's end (3)" do
        expect(node.right_node).not_to have_received(:search)
      end
    end
  end
end

describe "IntervalTree::Tree" do
  describe '#center' do
    context 'given [(1...5),]' do
      it 'returns 3' do
        itvs = [(1...5),]
        t = IntervalTree::Tree.new([])
        expect(t.__send__(:center, itvs)).to be == 3.0

      end
    end

    context 'given [(1...5), (2...6)]' do
      it 'returns 3' do
        itvs = [(1...5), (2...6),]
        t = IntervalTree::Tree.new([])
        expect(t.__send__(:center, itvs)).to be == 3.5
      end
    end
  end

  describe '.new' do
    context 'given [(1...5)]' do
      it 'returns a Tree' do
        itvs = [(1...5)]
        expect(IntervalTree::Tree.new(itvs)).to be_an IntervalTree::Tree
      end
    end

    context 'given [(1...5),(2...6), (3...7)]' do
      it 'returns ret.top_node.x_centeran == 4' do
        itvs = [(1...5), (2...6), (3...7)]
        tree = IntervalTree::Tree.new(itvs)
        expect(tree.top_node.x_center).to be == 4.0
      end
    end

    context 'given [(1..5),(2..6), (3..7)]' do
      it 'returns ret.top_node.x_centeran == 4 ' do
        itvs = [(1..5), (2..6), (3..7)]
        tree = IntervalTree::Tree.new(itvs)
        expect(tree.top_node.x_center).to be == 4.5
      end
    end

    context 'with custom objects' do
      CustomStruct = Struct.new(:begin, :end, :value)
      context 'given [CustomStruct.new(1, 6, "value one"), CustomStruct.new(5, 11, "value two")]' do
        it 'does not raise an exception' do
          itvs = [CustomStruct.new(1, 6, "value one"), CustomStruct.new(5, 11, "value two")]
          expect {IntervalTree::Tree.new(itvs)}.not_to raise_exception
        end
      end
    end

    context 'with a custom range factory' do
      class ValueRange < Range
        attr_accessor :value
        def initialize(l, r, value = nil)
          super(l, r, true)
          @value = value
        end
      end
      context 'given [(1..5)] and a ValueRange factory block' do
        it 'constructs a range with a value' do
          itvs = [(1..5)]
          tree = IntervalTree::Tree.new(itvs) { |l, r| ValueRange.new(l, r, 15) }
          result = tree.search(2).first
          expect(result).to be_kind_of ValueRange
          expect(result.value).to be == 15
        end
      end
    end

    describe 'dividing intervals' do
      subject(:tree) do
        IntervalTree::Tree.new(
          [
            10...14,
            2...20,
            0...5,
            0...8,
            3...6,
            15...20,
            16...21,
            17...25,
            21...24,
          ],
        )
      end

      let(:node) do
        IntervalTree::Node.new(
          12.5, # x_center
          [ 2...20, 10...14 ], # s_center
          left_node, # s_left
          right_node, # s_right
        )
      end
      let(:left_node) do
        IntervalTree::Node.new(
          4, # x_center
          [ 0...5, 0...8, 3...6 ], # s_center
          nil, # s_left
          nil, # s_right
        )
      end
      let(:right_node) do
        IntervalTree::Node.new(
          20, # x_center
          [ 15...20, 16...21, 17...25 ], # s_center
          nil, # s_left
          right_node_of_right_node, # s_right
        )
      end
      let(:right_node_of_right_node) do
        IntervalTree::Node.new(
          22.5, # x_center
          [ 21...24 ], # s_center
          nil, # s_left
          nil, # s_right
        )
      end

      context 'given a set of intervals' do
        it 'divides everything correctly' do
          expect(tree.top_node).to eq(node)
        end

        it 'divides into a left node correctly' do
          expect(tree.top_node.left_node).to eq(left_node)
        end

        it 'divides into a right node correctly' do
          expect(tree.top_node.right_node).to eq(right_node)
        end

        it 'divides the right node into a right node correctly' do
          expect(tree.top_node.right_node.right_node).to eq(right_node_of_right_node)
        end
      end
    end
  end

  describe '#search' do
    context 'given []' do
      it 'returns nil for all searches' do
        itvs = []
        IntervalTree::Tree.new(itvs).tap do |tree|
          expect(tree.search(5)).to be_nil
          expect(tree.search(1..2)).to be_nil
          expect(tree.search(1...2)).to be_nil
        end
      end
    end

    context 'given [(1...5)] and a point query "3"' do
      it 'returns an array of intervals (1...5)]' do
        expect(IntervalTree::Tree.new([1...5]).search(3)).to be == [1...5]
      end

      it 'returns an empty array in the right end corner case' do
        expect(IntervalTree::Tree.new([1...5]).search(5)).to be == []
      end

      it 'returns the range in the left end corner case' do
        expect(IntervalTree::Tree.new([1...5]).search(1)).to be == [1...5]
      end
    end

    context 'given non-array full-closed "(1..4)" and a point query "3"' do
      it 'returns an array contains a half-open interval (1...5)]' do
        expect(IntervalTree::Tree.new(1..4).search(4)).to be == [1...5]
      end

      it 'returns an empty array in the right end corner case' do
        expect(IntervalTree::Tree.new(1..4).search(5)).to be == []
      end

      it 'returns the range in the left end corner case' do
        expect(IntervalTree::Tree.new(1..4).search(1)).to be == [1...5]
      end
    end

    context 'given [(1...5), (2...6)] and a point query "3"' do
      it 'returns [(1...5), (2...6)]' do
        itvs = [(1...5), (2...6),]
        results = IntervalTree::Tree.new(itvs).search(3)
        expect(results).to be == itvs
      end
    end

    context 'given [(0...30),(20...100)] and a sorted point query "25"' do
      it 'returns [(0...30),(20...100)]' do
        itvs = [(0...30),(20...100)]

        results = IntervalTree::Tree.new(itvs).search(25, unique: false, sort: true)
        expect(results).to match_array([(0...30),(20...100)])
      end
    end

    context 'given [(0...30),(20...100)] and an unsorted point query "25"' do
      it 'returns [(20...100),(0...30)]' do
        itvs = [(0...30),(20...100)]

        results = IntervalTree::Tree.new(itvs).search(25, unique: false, sort: false)
        expect(results).to match_array([(20...100), (0...30)])
      end
    end

    context 'given [(0...8), (1...5), (2...6)] and a point query "3"' do
      it 'returns [(0...8), (1...5), (2...6)]' do
        itvs = [(0...8), (1...5), (2...6)]
        results = IntervalTree::Tree.new(itvs).search(3)
        expect(results).to be == itvs
      end
    end

    context 'given [(0...8), (1...5), (2...6)] and a query by (1...4)' do
      it 'returns [(0...8), (1...5), (2...6)]' do
        itvs = [(0...8), (1...5), (2...6)]
        results = IntervalTree::Tree.new(itvs).search(1...4)
        expect(results).to be == itvs
      end
    end

    context 'given [(1...3), (3...5)] and a query by (3...9)' do
      it 'returns [(3...5)]' do
        results = IntervalTree::Tree.new([(1...3), (3...5)]).search(3...9)
        expect(results).to be == [(3...5)]
      end
    end

    context 'given [(1...3), (3...5), (4...8)] and a query by (3...5)' do
      it 'returns [(3...5), (4...8)]' do
        itvs = [(1...3), (3...5), (4...8)]
        results = IntervalTree::Tree.new(itvs).search(3...5)
        expect(results).to be == [(3...5), (4...8)]
      end
    end

    context 'given [(1...3), (3...5), (3...9), (4...8)] and a query by (3...5)' do
      it 'returns [(3...5), (3...9), (4...8)]' do
        itvs = [(1...3), (3...5), (3...9), (4...8)]
        results = IntervalTree::Tree.new(itvs).search(3...5)
        expect(results).to be == [(3...5), (3...9), (4...8)]
      end
    end
    
    context 'with unique defaulting to true, given intervals with duplicates' do
      context 'given [(1...3), (3...5), (3...9), (4...8), (4...8)] and a query by (3...5)]' do
        it 'removes the duplicates in the result' do
          itv = [(1...3), (3...5), (3...9), (4...8), (4...8)]
          t = IntervalTree::Tree.new(itv)
          results = t.search((3...5))
          
          expect(results).to match_array([(3...5), (3...9), (4...8)])
        end
      end

      context 'given [(0...3), (1...4), (3...5), (0...3)] and a query by (2)' do
        it 'removes the duplicates in the result' do
          itv = [(0...3), (1...4), (3...5), (0...3)]
          t = IntervalTree::Tree.new(itv)
          results = t.search(2)
          expect(results).to match_array([0...3, 1...4])
        end
      end
    end

    context 'with unique: false' do
      context 'given [(1...3), (1...3), (2...4), (1...3)] and a query by (1)' do
        it 'returns [(1...3), (1...3), (1...3)]' do
          itvs = [(1...3), (1...3), (2...4), (1...3)]
          results = IntervalTree::Tree.new(itvs).search(1, unique: false)
          expect(results).to match_array([(1...3), (1...3), (1...3)])
        end
      end

      context 'given [(1...3), (1...3), (2...4), (1...3)] and a query by (3)' do
        it 'returns [(2..4)]' do
          itvs = [(1...3), (1...3), (2...4), (1...3)]
          results = IntervalTree::Tree.new(itvs).search(3, unique: false)
          expect(results).to match_array([(2...4)])
        end
      end

      context 'given [(0...5), (1...5), (3...5), (3...5)] and a query by (3)' do
        it 'returns [(0...5), (1...5), (3...5), (3...5)]' do
          itvs = [(0...5), (1...5), (3...5), (3...5)]
          results = IntervalTree::Tree.new(itvs).search(3, unique: false)
          expect(results).to match_array([(0...5), (1...5), (3...5), (3...5)])
        end
      end

      context 'given [(0...3), (1...4), (3...4), (3...4), (3...5)] and a query by (3)' do
        it 'returns [(1...4), (3...4), (3...4), (3...5)]' do
          itvs = [(0...3), (1...4), (3...4), (3...4), (3...5)]
          results = IntervalTree::Tree.new(itvs).search(3, unique: false)
          expect(results).to match_array([(1...4), (3...4), (3...4), (3...5)])
        end
      end

      context 'given [(0...2), (0...2), (1...2), (1...2), (2...5)] and a query by (1)' do
        it 'returns [(0...2), (0...2), (1...2), (1...2)]' do
          itvs = [(0...2), (0...2), (1...2), (1...2), (2...5)]
          results = IntervalTree::Tree.new(itvs).search(1, unique: false)
          expect(results).to match_array([(0...2), (0...2), (1...2), (1...2)])
        end
      end

    end

    context "when concerned with performance" do
      context "with a small search space of very large ranges" do
        it "should still be fast" do
          itvs = [1...10_000_000]
          needle = 5_000_001...15_000_000

          a = Time.now
          results = IntervalTree::Tree.new(itvs).search(needle)
          b = Time.now

          expect(b - a).to be_within(0.05).of(0)
        end
      end
    end

    context 'when using time ranges' do
      it 'still works' do
        itvs = [Time.utc(2020, 11, 1)...Time.utc(2020, 11, 20)]
        needle = Time.utc(2020, 11, 5)...Time.utc(2020, 11, 6)
        results = IntervalTree::Tree.new(itvs).search(needle)
        expect(results).to eq(itvs)
      end
    end

    context 'when using custom objects' do
      CustomStruct = Struct.new(:begin, :end, :value)
      context 'given [CustomStruct.new(1, 6, "value one"), CustomStruct.new(5, 11, "value two")]' do
        it 'can search by point' do
          itvs = [CustomStruct.new(1, 6, "value one"), CustomStruct.new(5, 11, "value two")]
          tree = IntervalTree::Tree.new(itvs)
          result = tree.search(2)
          expect(result).to be_kind_of Array
          item = result.first
          expect(item).to be_kind_of CustomStruct
          expect(item.value).to be == "value one"
        end

        it 'can search by range' do
          itvs = [CustomStruct.new(1, 6, "value one"), CustomStruct.new(5, 11, "value two")]
          tree = IntervalTree::Tree.new(itvs)
          result = tree.search(4...7)
          expect(result).to be == itvs
          result = tree.search(9...20)
          expect(result).to be_kind_of Array
          item = result.first
          expect(item).to be == CustomStruct.new(5, 11, "value two")
        end

        it 'can search by the custom object' do
          itvs = [CustomStruct.new(1, 6, "value one"), CustomStruct.new(5, 11, "value two")]
          tree = IntervalTree::Tree.new(itvs)
          result = tree.search(CustomStruct.new(4,7))
          expect(result).to be == itvs
        end
      end
    end
  end
end