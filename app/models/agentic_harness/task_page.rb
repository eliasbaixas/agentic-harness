# frozen_string_literal: true

# Value object representing a single Markdown task file from tasks/.
#
# File layout convention:
#   tasks/00_inbox/T-0001-foo.md  → column "inbox",  slug "T-0001-foo"
#   tasks/20_in_progress/B-0002.md → column "in_progress", slug "B-0002"
#
# Also handles special root-level files (BACKLOG.md, README.md, _index.md).
#
module AgenticHarness
class TaskPage
  # Resolved at call time (not boot) so the host app can swap configuration
  # in initializers / per-environment without restart-sensitive constants.
  def self.tasks_root
    AgenticHarness.configuration.tasks_root
  end

  CATEGORIES = {
    "product"   => "Product",
    "marketing" => "Marketing",
    "it"        => "IT"
  }.freeze

  COLUMNS = {
    "00_inbox"        => { label: "Inbox",       color: "gray",   order: 0 },
    "10_todo"         => { label: "Todo",        color: "blue",   order: 1 },
    "20_in_progress"  => { label: "In Progress", color: "amber",  order: 2 },
    "30_blocked"      => { label: "Blocked",     color: "red",    order: 3 },
    "40_done"         => { label: "Done",        color: "green",  order: 4 },
    "90_archive"      => { label: "Archive",     color: "slate",  order: 5 }
  }.freeze

  attr_reader :slug, :column, :frontmatter, :body, :path

  def self.all_by_column(category: nil)
    result = COLUMNS.keys.index_with { |_| [] }

    COLUMNS.each_key do |col|
      dir = tasks_root.join(col)
      next unless dir.directory?

      Dir.glob(dir.join("*.md")).each do |f|
        slug = File.basename(f, ".md")
        task = new(slug, col, Pathname.new(f))
        next if category.present? && task.category != category

        result[col] << task
      end
      result[col].sort_by! { |t| [t.order || Float::INFINITY, t.slug] }
    end

    result
  end

  # Rewrites the `order:` frontmatter field in each task file to match the
  # given slug order. Slugs not found on disk are silently skipped.
  def self.reorder_column(column, slugs)
    return unless COLUMNS.key?(column)

    slugs.each_with_index do |slug, idx|
      next unless slug.to_s.match?(/\A[\w\-]+\z/)

      path = tasks_root.join(column, "#{slug}.md")
      next unless path.exist? && path.to_s.start_with?(tasks_root.to_s)

      content = path.read
      if content.match?(/^order:/)
        content = content.sub(/^order:.*$/, "order: #{idx}")
      elsif content.start_with?("---")
        content = content.sub(/\A---\n/, "---\norder: #{idx}\n")
      end
      path.write(content)
    end
  end

  def self.find(column, slug)
    return nil unless COLUMNS.key?(column)
    return nil unless slug.present? && slug.match?(/\A[\w\-]+\z/)

    path = tasks_root.join(column, "#{slug}.md")
    return nil unless path.to_s.start_with?(tasks_root.to_s)
    return nil unless path.exist?

    new(slug, column, path)
  end

  # Moves a task between kanban columns.
  #
  # With symlinks (the default layout): the actual card file lives permanently
  # under tasks/cards/YYYY/MM/ and status directories hold symlinks.
  # Moving = delete old symlink, create new symlink, update status in card.
  #
  # Falls back to file-copy semantics if the path is a regular file.
  def self.move(task, target_column)
    return nil unless COLUMNS.key?(target_column)

    new_link = tasks_root.join(target_column, "#{task.slug}.md")
    return nil if new_link.cleanpath == task.path.cleanpath

    status_map = {
      "00_inbox"       => "inbox",
      "10_todo"        => "todo",
      "20_in_progress" => "in_progress",
      "30_blocked"     => "blocked",
      "40_done"        => "done",
      "90_archive"     => "archive",
    }
    new_status = status_map[target_column]

    if task.path.symlink?
      # Symlink layout: update the card file in place, swap the symlink.
      card_path = task.path.realpath
      content = card_path.read
      content = update_card_status(content, task, new_status, target_column)

      card_path.write(content)
      FileUtils.mkdir_p(new_link.dirname)
      rel = card_path.relative_path_from(new_link.dirname)
      task.path.delete
      File.symlink(rel.to_s, new_link.to_s)
    else
      # Legacy flat-file layout: copy content to new location.
      content = task.path.read
      updated = update_card_status(content, task, new_status, target_column)
      FileUtils.mkdir_p(new_link.dirname)
      new_link.write(updated)
      task.path.delete
    end

    new(task.slug, target_column, new_link)
  end

  def self.backlog
    path = tasks_root.join("BACKLOG.md")
    return nil unless path.exist?

    new("BACKLOG", nil, path)
  end

  # Returns the next available task ID (e.g. "T-0034") by scanning all card
  # files across every tasks/cards/YYYY/MM/ directory for the highest T-NNNN.
  def self.next_id
    max = 0
    Dir.glob(tasks_root.join("cards", "**", "T-*.md")).each do |f|
      if File.basename(f) =~ /\AT-(\d+)/
        max = [max, $1.to_i].max
      end
    end
    format("T-%04d", max + 1)
  end

  # Creates a new task card in the current month's directory and symlinks it
  # into the target column (defaults to 00_inbox).
  #
  #   TaskPage.create(title: "Fix login bug", category: "product", tags: ["auth"])
  #
  def self.create(title:, category: "product", priority: "P2", tags: [], column: "00_inbox", owner: "")
    id = next_id
    slug = "#{id}-#{title.parameterize}"
    today = Date.current
    card_dir = tasks_root.join("cards", today.strftime("%Y"), today.strftime("%m"))
    FileUtils.mkdir_p(card_dir)

    status = { "00_inbox" => "inbox", "10_todo" => "todo", "20_in_progress" => "in_progress" }[column] || "inbox"

    content = <<~MD
      ---
      id: #{id}
      title: "#{title.gsub('"', '\\"')}"
      status: #{status}
      category: #{category}
      priority: #{priority}
      owner: "#{owner}"
      created: #{today}
      tags: [#{tags.join(', ')}]
      deps: []
      ---

      ## Context

      _TODO: describe the problem or opportunity._

      ## Objective

      _TODO: what does "done" look like?_

      ## Acceptance criteria

      - [ ] _TODO_

      ## Log

      - #{today}: created
    MD

    card_path = card_dir.join("#{slug}.md")
    card_path.write(content)

    # Symlink into the column directory
    col_dir = tasks_root.join(column)
    FileUtils.mkdir_p(col_dir)
    link_path = col_dir.join("#{slug}.md")
    rel = card_path.relative_path_from(col_dir)
    File.symlink(rel.to_s, link_path.to_s)

    new(slug, column, link_path)
  end

  def self.counts
    COLUMNS.transform_values do |meta|
      dir = tasks_root.join(COLUMNS.key(meta))
      next 0 unless dir.directory?

      Dir.glob(dir.join("*.md")).count
    end
  end

  def initialize(slug, column, path)
    @slug   = slug
    @column = column
    @path   = path
    parse(path.read)
  end

  def title
    frontmatter["title"].presence || slug.tr("-", " ").sub(/\A[TB] \d+ /, "")
  end

  def id
    frontmatter["id"]
  end

  def priority
    frontmatter["priority"]
  end

  def status
    frontmatter["status"]
  end

  def category
    frontmatter["category"]
  end

  def tags
    Array(frontmatter["tags"])
  end

  def deps
    Array(frontmatter["deps"])
  end

  def order
    frontmatter["order"]&.to_i
  end

  def created
    frontmatter["created"]
  end

  def owner
    frontmatter["owner"]
  end

  # Resolution records the outcome when a card is archived (e.g. "done",
  # "wont_do", "superseded"). Preserved across moves so you always know
  # whether an archived card was completed or abandoned.
  def resolution
    frontmatter["resolution"]
  end

  def column_label
    COLUMNS.dig(column, :label) || column
  end

  def column_color
    COLUMNS.dig(column, :color) || "gray"
  end

  def rendered_html
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      hard_wrap:   false,
      link_attributes: { rel: "noopener noreferrer" }
    )
    md = Redcarpet::Markdown.new(
      renderer,
      autolink:           true,
      tables:             true,
      fenced_code_blocks: true,
      strikethrough:      true,
      highlight:          true,
      footnotes:          true
    )
    md.render(body).html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def parse(raw)
    if raw.start_with?("---")
      parts = raw.split(/^---\s*$/, 3)
      if parts.length == 3
        @frontmatter = YAML.safe_load(parts[1].strip, permitted_classes: [Date, Symbol]) || {}
        @body        = parts[2].lstrip
        return
      end
    end
    @frontmatter = {}
    @body        = raw
  end

  # Rewrites status (and resolution) in card frontmatter content.
  # When archiving, records the previous status as the resolution so we
  # know whether the card was "done" or abandoned. When un-archiving
  # (moving out of archive), the resolution field is preserved.
  def self.update_card_status(content, task, new_status, target_column)
    updated = content.sub(/^status:.*$/, "status: #{new_status}")

    if target_column == "90_archive"
      resolution = task.status || task.column&.sub(/^\d+_/, "")
      if updated.match?(/^resolution:/)
        updated = updated.sub(/^resolution:.*$/, "resolution: #{resolution}")
      else
        updated = updated.sub(/^status:.*$/, "status: #{new_status}\nresolution: #{resolution}")
      end
    end

    updated
  end
end
end
