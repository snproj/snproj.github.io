--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections #-}
import           Data.Monoid (mappend)
import           Hakyll
import Data.Maybe
import Text.Read (readMaybe)
import Data.List (sortBy)
import Data.Ord (comparing)
import Control.Monad (liftM)
import Data.Map (fromList, Map, lookup)


--------------------------------------------------------------------------------
config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "docs"
    }

tagDescMap :: Map String String
tagDescMap = Data.Map.fromList [
    ("Cat Haikus", "Haikus written in broken Japanese, as well as other feline edits. Pictures not taken by me."),
    ("The Curse of Hardware", "The Curse of Hardware is a concept I think is interesting to ponder.")
    ]

main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "bio.txt" $ do
        route idRoute
        compile copyFileCompiler

    match (Hakyll.fromList ["about.markdown", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    tags <- buildTags "posts/**" (fromCapture "tags/*.html")
    tagsRules tags $ \tag pattern -> do
        let title = tag
        let desc = fromJust $ Data.Map.lookup tag tagDescMap
        route idRoute
        compile $ do
            posts <- byCoolness =<< loadAll pattern
            let ctx = constField "title" title
                    `mappend` constField "desc" desc
                    `mappend` listField "posts" (postCtxWithTags tags) (return posts)
                    `mappend` defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/tag.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    match "posts/**" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    (postCtxWithTags tags)
            >>= loadAndApplyTemplate "templates/default.html" (postCtxWithTags tags)
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/**"
            let archiveCtx =
                    listField "posts" (postCtxWithTags tags) (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/**"
            let indexCtx =
                    listField "posts" (postCtxWithTags tags) (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

postCtxWithTags :: Tags -> Context String
postCtxWithTags tags = tagsField "tags" tags `mappend` postCtx

-- this parses the coolness out of an item
-- it defaults to 0 if it's missing, or can't be parsed as an Int
coolness :: (MonadMetadata m) => Item a -> m Int
coolness i = do
  mStr <- getMetadataField (itemIdentifier i) "sort"
  return $ (fromMaybe 0 $ mStr >>= readMaybe)

byCoolness :: (MonadMetadata m) => [Item a] -> m [Item a]
byCoolness = sortByM coolness
  where
    sortByM :: (Monad m, Ord k) => (a -> m k) -> [a] -> m [a]
    sortByM f xs =
      liftM (map fst . sortBy (comparing snd)) $
        mapM (\x -> liftM (x,) (f x)) xs