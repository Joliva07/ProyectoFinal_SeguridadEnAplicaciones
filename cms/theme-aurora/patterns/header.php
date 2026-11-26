<?php
/**
 * Title: AuroraShop: encabezado
 * Slug: aurora-child/header
 * Categories: header
 * Block Types: core/template-part/header
 * Inserter: no
 *
 * Unica pieza con PHP del tema: solo construye la URL del logo, escapada con esc_url().
 * No lee entrada del usuario ni consulta la base de datos.
 */

defined('ABSPATH') || exit;
?>
<!-- wp:group {"align":"full","className":"aurora-announce","style":{"spacing":{"padding":{"top":"0.5rem","bottom":"0.5rem"}}},"backgroundColor":"contrast","textColor":"base","layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull aurora-announce has-base-color has-contrast-background-color has-text-color has-background" style="padding-top:0.5rem;padding-bottom:0.5rem">
	<!-- wp:paragraph {"align":"center"} -->
	<p class="has-text-align-center">Envíos a toda Guatemala · Pago seguro · Tienda de demostración</p>
	<!-- /wp:paragraph -->
</div>
<!-- /wp:group -->

<!-- wp:group {"align":"full","style":{"border":{"bottom":{"color":"var:preset|color|accent-6","width":"1px"}}},"layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull" style="border-bottom-color:var(--wp--preset--color--accent-6);border-bottom-width:1px">
	<!-- wp:group {"align":"wide","style":{"spacing":{"padding":{"top":"var:preset|spacing|20","bottom":"var:preset|spacing|20"}}},"layout":{"type":"flex","flexWrap":"nowrap","justifyContent":"space-between"}} -->
	<div class="wp-block-group alignwide" style="padding-top:var(--wp--preset--spacing--20);padding-bottom:var(--wp--preset--spacing--20)">
		<!-- wp:group {"style":{"spacing":{"blockGap":"0.6rem"}},"layout":{"type":"flex","flexWrap":"nowrap"}} -->
		<div class="wp-block-group">
			<!-- wp:html -->
			<a class="aurora-logo" href="/" aria-label="AuroraShop, inicio"><img src="<?php echo esc_url(get_theme_file_uri('assets/images/logo.svg')); ?>" alt="" width="40" height="40"></a>
			<!-- /wp:html -->
			<!-- wp:site-title {"level":0,"isLink":true,"style":{"typography":{"fontWeight":"800","letterSpacing":"-0.02em"}},"fontSize":"large"} /-->
		</div>
		<!-- /wp:group -->

		<!-- wp:group {"style":{"spacing":{"blockGap":"var:preset|spacing|20"}},"layout":{"type":"flex","flexWrap":"nowrap","justifyContent":"right"}} -->
		<div class="wp-block-group">
			<!-- wp:navigation {"overlayBackgroundColor":"base","overlayTextColor":"contrast","style":{"typography":{"fontWeight":"600"}},"layout":{"type":"flex","justifyContent":"right","flexWrap":"wrap"}} -->
				<!-- wp:navigation-link {"label":"Inicio","url":"/","kind":"custom"} /-->
				<!-- wp:navigation-link {"label":"Tienda","url":"/shop/","kind":"custom"} /-->
				<!-- wp:navigation-link {"label":"Mi cuenta","url":"/my-account/","kind":"custom"} /-->
			<!-- /wp:navigation -->
			<!-- wp:woocommerce/mini-cart /-->
		</div>
		<!-- /wp:group -->
	</div>
	<!-- /wp:group -->
</div>
<!-- /wp:group -->
