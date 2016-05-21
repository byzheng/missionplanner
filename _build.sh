set -e
# configure your name and email if you have not done so
git config --global user.email "zheng.bangyou@gmail.com"
git config --global user.name "Bangyou Zheng"
git clone --branch=gh-pages \
  https://github.com/${TRAVIS_REPO_SLUG}.git \
  shiny
cd shiny
Rscript -e "rsconnect::deployApp(quite=TRUE)"
