SiteChef CLI
============

The SiteChef CLI simplifies the process of creating, editing and publishing
themes on SiteChef.

With two commands ("sitechef init <api-code>", "sitechef serve") the CLI tool
will download all necessary theme assets, a frontend asset pipeline and a JSON
data snapshot of your site. SiteChef then compiles frontend assets and serves
the theme at http://localhost:3999/


#Installation

1. Install [Node.js](http://nodejs.org/download/)

2. Install the SiteChef CLI:

        npm install -g sitechef


#Editing a Theme


##Setup a theme for editing on SiteChef

1. Once you have signed up to SiteChef, login at https://admin.sitechef.co.uk

2. Click on "Your Account" and ensure that "Developer Mode" is turned on

3. Click on "Theme Manager" in the main menu then "New Theme/ Clone Existing"

4. Update the name of the theme and choose whether it is private

5. Click "Clone" and you will be assigned an api key


##Downloading and running your theme locally

1. Open the Terminal (Mac / Linux) or Command (windows)

2. Copy the api key from the website and enter

        sitechef init <your-api-code> <a-name-for-the-new-directory>

3. To preview the theme move into the directory

        cd <your-new-directory>

        sitechef serve


4. Open [http://localhost:3999/](http://localhost:3999/) in your browser


##Publishing your theme back to sitechef


Navigate to your theme directory in the Terminal / Command

        sitechef publish


#Templating

##Local File Structure

##HTML Templates
- SiteChef uses Nunjucks - a javascript implementation of the Jinja2 templating engine

##CSS

- SiteChef uses [SCSS](http://sass-lang.com) for creating the CSS files

- The entry point for generating the CSS file is sass/theme.scss

- We recommend creating a new SCSS file for each component on your theme
  and importing them in the main theme.scss file

##Javascript

- The default theme setup uses [Browserify](http://browserify.org/) to compile
  multiple source files into a single javascript file, but you are free to use
  any system you please.

- SiteChef has developed a number of frontend modules which you may use in any
  SiteChef-hosted theme

- Your production javascript files should be output to the dist/js/ folder

- By default all source javascript files are placed in the js/ folder

##Coffeescript

- By default we have a coffeescript workflow that works by compiling and uglifying
  the app.coffee coffeescript file in the coffee/ folder


#Best Practices

- *Use version control*. Version control will save you a lot of time
  by being able to move back to previous versions without losing
  valuable code. We recommend using GIT. If you're not that comfortable
  with the command line, then consider using [Source Tree](https://www.atlassian.com/software/sourcetree/overview)
  Bitbucket.org offers free private repositories for backing up your code

- Keep your template *modular*. This ensures that you don't end up repeating yourself
  and having to copy and paste code multiple times.

- Use variables where possible. Both SCSS and Nunjucks allow for you to create variables






