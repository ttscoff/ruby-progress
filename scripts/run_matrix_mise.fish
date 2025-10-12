#!/usr/bin/env fish
# Runs the test matrix using mise-managed Ruby installs and writes per-version logs.
# Safe for fish shell; intended to be run from project root.

set -l VERSIONS 2.7.8 3.0.6 3.1.4 3.2.0 3.3.0
set -l REPO_ROOT (pwd)

for v in $VERSIONS
    set -l bin_dir $HOME/.local/share/mise/installs/ruby/$v/bin
    if test -x "$bin_dir/ruby"
        echo "\n=== Ruby $v ==="
        echo "ruby: " (printf "%s" ("$bin_dir/ruby" -v))
        echo "Installing bundler for Ruby $v (if needed)" >&2
        # install bundler quietly; ignore errors from this step so we can try bundle install next
        "$bin_dir/gem" install bundler --no-document >/dev/null 2>&1 || true
        echo "Running bundle install for Ruby $v" >&2
        # Use --quiet to reduce log noise, but keep failures visible
        if test -x "$bin_dir/bundle"
            "$bin_dir/bundle" install --quiet
        else
            # try using bundler directly
            "$bin_dir/ruby" -S gem install bundler --no-document
            "$bin_dir/ruby" -S bundle install --quiet
        end

        echo "Running rspec for Ruby $v (output -> rspec-$v.log)" >&2
        # Capture exit status per-version; write logs
        # run rspec and tee output to a per-version log
        "$bin_dir/bundle" exec rspec --format documentation 2>&1 | tee rspec-$v.log
        if test $status -ne 0
            echo "rspec failed for Ruby $v (exit $status)" >&2
            # stop the matrix if a version fails
            exit $status
        end
    else
        echo "Ruby $v not found at $bin_dir, skipping"
    end
end

echo "Matrix complete. Logs:"
ls -1 rspec-*.log 2>/dev/null || echo "No logs found"
