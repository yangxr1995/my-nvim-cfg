return {
    "williamboman/mason.nvim",
    event = {'BufReadPost', 'BufNewFile', 'VimEnter'},
    opts = {
        github = {
            ---@since 1.0.0
            -- The template URL to use when downloading assets from GitHub.
            -- The placeholders are the following (in order):
            -- 1. The repository (e.g. "rust-lang/rust-analyzer")
            -- 2. The release version (e.g. "v0.3.0")
            -- 3. The asset name (e.g. "rust-analyzer-v0.3.0-x86_64-unknown-linux-gnu.tar.gz")
            -- download_url_template = "http://127.0.0.1:8080/%s/releases/download/%s/%s",
        },
    }
}
