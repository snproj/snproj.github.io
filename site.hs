--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll


--------------------------------------------------------------------------------
config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "docs"
    }

main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.markdown", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "cathaikus/*" $ do
        route $ setExtension "html"
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/cathaiku.html" catHaikuCtx
                >>= loadAndApplyTemplate "templates/default.html" catHaikuCtx
                >>= relativizeUrls

    create ["cathaikuselectpage.html"] $ do
        route idRoute
        compile $ do
            catHaikus <- loadAll "cathaikus/*"
            let catHaikuSelectPageCtx =
                    listField "cathaikus" catHaikuCtx (return catHaikus)
                    `mappend` constField "title" "Cat Haikus"
                    `mappend` defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/cathaikuselectpage.html" catHaikuSelectPageCtx
                >>= loadAndApplyTemplate "templates/default.html" catHaikuSelectPageCtx
                >>= relativizeUrls

    match "bio.txt" $ do
        route idRoute
        compile copyFileCompiler

    match "index.html" $ do
        route idRoute
        compile $ do
            let indexCtx =
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------

catHaikuCtx :: Context String
catHaikuCtx =
  defaultContext
