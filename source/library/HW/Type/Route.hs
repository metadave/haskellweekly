-- | This module defines a type for all of the routes that the server knows
-- about. By representing the possible routes as a type, it's possible to do
-- type safe routing.
module HW.Type.Route
  ( Route(..)
  , routeToTextWith
  , textToRoute
  )
where

import qualified Data.Text
import qualified HW.Type.BaseUrl
import qualified HW.Type.Number
import qualified HW.Type.Redirect

data Route
  = RouteAdvertising
  | RouteAppleBadge
  | RouteEpisode HW.Type.Number.Number
  | RouteFavicon
  | RouteGoogleBadge
  | RouteIndex
  | RouteIssue HW.Type.Number.Number
  | RouteNewsletter
  | RouteNewsletterFeed
  | RoutePodcast
  | RoutePodcastFeed
  | RoutePodcastLogo
  | RouteRedirect HW.Type.Redirect.Redirect
  | RouteRobots
  | RouteSitemap
  | RouteTachyons
  deriving (Eq, Show)

-- | Returns true if the route is a redirect, false otherwise.
isRedirect :: Route -> Bool
isRedirect route = case route of
  RouteRedirect _ -> True
  _ -> False

-- | Renders a route as text.
routeToText :: Route -> Data.Text.Text
routeToText route = case route of
  RouteAdvertising -> "/advertising.html"
  RouteAppleBadge -> "/apple-badge.svg"
  RouteEpisode number ->
    "/podcast/episodes/" <> HW.Type.Number.numberToText number <> ".html"
  RouteFavicon -> "/favicon.ico"
  RouteGoogleBadge -> "/google-badge.svg"
  RouteIndex -> "/"
  RouteIssue number ->
    "/issues/" <> HW.Type.Number.numberToText number <> ".html"
  RouteNewsletterFeed -> "/haskell-weekly.atom"
  RouteNewsletter -> "/newsletter.html"
  RoutePodcastFeed -> "/podcast/feed.rss"
  RoutePodcastLogo -> "/podcast/logo.png"
  RoutePodcast -> "/podcast.html"
  RouteRedirect redirect -> HW.Type.Redirect.redirectToText redirect
  RouteRobots -> "/robots.txt"
  RouteSitemap -> "/sitemap.txt"
  RouteTachyons -> "/tachyons.css"

-- | Renders a route as text with the given base URL. Redirects are not
-- affected by the base URL, but everything else is.
routeToTextWith :: HW.Type.BaseUrl.BaseUrl -> Route -> Data.Text.Text
routeToTextWith baseUrl route = if isRedirect route
  then routeToText route
  else mappend (HW.Type.BaseUrl.baseUrlToText baseUrl) $ routeToText route

-- | Parses a list of strings as a route. Note that some lists of strings go to
-- the same place, so this isn't necessarily a one to one mapping.
textToRoute :: [Data.Text.Text] -> Maybe Route
textToRoute path = case path of
  [] -> Just RouteIndex
  ["advertising.html"] -> Just RouteAdvertising
  ["apple-badge.svg"] -> Just RouteAppleBadge
  ["favicon.ico"] -> Just RouteFavicon
  ["google-badge.svg"] -> Just RouteGoogleBadge
  ["index.html"] -> Just $ routeToRedirect RouteIndex
  ["haskell-weekly.atom"] -> Just RouteNewsletterFeed
  ["newsletter.html"] -> Just RouteNewsletter
  ["issues", file] -> routeContent "html" RouteIssue file
  ["podcast", "episodes", file] -> routeContent "html" RouteEpisode file
  ["podcast", "feed.rss"] -> Just RoutePodcastFeed
  ["podcast.html"] -> Just RoutePodcast
  ["podcast"] -> Just $ routeToRedirect RoutePodcast
  ["podcast", ""] -> Just $ routeToRedirect RoutePodcast
  ["podcast", "logo.png"] -> Just RoutePodcastLogo
  ["robots.txt"] -> Just RouteRobots
  ["sitemap.txt"] -> Just RouteSitemap
  ["tachyons.css"] -> Just RouteTachyons
  _ -> Nothing

-- | Handles routing content by stripping the given extension, parsing what's
-- left of the path, and wrapping the result in a route.
routeContent
  :: Data.Text.Text
  -> (HW.Type.Number.Number -> HW.Type.Route.Route)
  -> Data.Text.Text
  -> Maybe HW.Type.Route.Route
routeContent extension route file =
  case Data.Text.stripSuffix ("." <> extension) file of
    Nothing -> Nothing
    Just text -> case HW.Type.Number.textToNumber text of
      Left _ -> Nothing
      Right value -> Just $ route value

-- | Converts a normal route into a redirect. This is handy when redirecting
-- old routes to their new canonical destinations.
routeToRedirect :: Route -> Route
routeToRedirect route = case route of
  RouteRedirect _ -> route
  _ -> RouteRedirect . HW.Type.Redirect.textToRedirect $ routeToText route